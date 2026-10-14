import { DecimalError, parseMoney, parseRate, sum } from '../shared/decimal.ts';
import { rucChecksumLooksValid, validateIdentityDocument } from '../shared/identity-document.ts';
import {
  ADJUSTMENT_ONLY_TYPES, CREDIT_NOTE_TYPES, DEBIT_NOTE_TYPES, NOTE_TYPES, RCE_DOCUMENT_TYPES, RVIE_DOCUMENT_TYPES,
} from './catalogs.ts';
import type { CompanyContext, Direction, Issue, Money, RegisterOperationInput } from './types.ts';

const OPERATION_TYPES = ['SALE', 'PURCHASE', 'EXPENSE', 'CREDIT_NOTE', 'DEBIT_NOTE', 'OTHER'];
const ISO_DATE = /^\d{4}-\d{2}-\d{2}$/;

function isRealDate(value: unknown): value is string {
  if (typeof value !== 'string' || !ISO_DATE.test(value)) return false;
  const d = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === value;
}

export function resolveDirection(input: RegisterOperationInput): Direction | undefined {
  switch (input.operation_type) {
    case 'SALE': return 'ISSUED';
    case 'PURCHASE':
    case 'EXPENSE': return 'RECEIVED';
    default: return input.direction;
  }
}

/** Validación estructural y aritmética de una operación. No decide ningún tratamiento tributario. */
export function validateRegisterOperation(input: RegisterOperationInput, ctx: CompanyContext): Issue[] {
  const issues: Issue[] = [];
  const err = (code: string, field: string, message: string) => issues.push({ severity: 'ERROR', code, field, message });
  const warn = (code: string, field: string, message: string) => issues.push({ severity: 'WARNING', code, field, message });
  const money = (field: string, value: Money | undefined, required = true): bigint | undefined => {
    if (value === undefined || value === null || value === '') {
      if (required) err('AMOUNT_REQUIRED', field, `${field} is required`);
      return undefined;
    }
    try {
      const cents = parseMoney(value);
      if (cents < 0n) { err('AMOUNT_NEGATIVE', field, `${field} must not be negative (notes carry positive amounts; sign is decided at SIRE mapping)`); return undefined; }
      return cents;
    } catch (e) {
      if (e instanceof DecimalError) { err('AMOUNT_INVALID', field, `${field}: ${e.message}`); return undefined; }
      throw e;
    }
  };

  if (!input.idempotency_key || input.idempotency_key.trim() === '') err('IDEMPOTENCY_KEY_REQUIRED', 'idempotency_key', 'idempotency_key is required');
  if (!OPERATION_TYPES.includes(input.operation_type)) err('OPERATION_TYPE_INVALID', 'operation_type', `unknown operation type "${input.operation_type}"`);
  if (!isRealDate(input.operation_date)) err('DATE_INVALID', 'operation_date', 'operation_date must be a valid YYYY-MM-DD date');

  // Moneda y tipo de cambio (RVIE campo 28, RCE campo 27: obligatorio si la moneda difiere de la de la contabilidad).
  const currency = input.currency ?? 'PEN';
  if (!/^[A-Z]{3}$/.test(currency)) err('CURRENCY_INVALID', 'currency', 'currency must be a 3-letter uppercase code');
  if (currency !== ctx.functionalCurrency) {
    if (input.exchange_rate === undefined || input.exchange_rate === '') {
      err('FX_REQUIRED', 'exchange_rate', `exchange_rate is required when currency (${currency}) differs from the accounting currency (${ctx.functionalCurrency})`);
    } else {
      try {
        if (parseRate(input.exchange_rate) <= 0n) err('FX_INVALID', 'exchange_rate', 'exchange_rate must be positive');
      } catch (e) {
        if (e instanceof DecimalError) err('FX_INVALID', 'exchange_rate', e.message); else throw e;
      }
    }
  }

  const direction = resolveDirection(input);
  const doc = input.document;
  let operationTotal: bigint | undefined;

  if (doc) {
    if (!direction) err('DIRECTION_REQUIRED', 'direction', 'direction (ISSUED or RECEIVED) is required for this operation type');
    const type = doc.document_type;
    if (!/^\d{2}$/.test(type)) err('DOC_TYPE_INVALID', 'document.document_type', 'document_type must be a 2-digit SUNAT code');
    else {
      if (ADJUSTMENT_ONLY_TYPES.includes(type)) err('DOC_TYPE_ADJUSTMENT_ONLY', 'document.document_type', `type ${type} is only valid for adjustments of periods before August 2021`);
      if (direction === 'ISSUED' && !RVIE_DOCUMENT_TYPES.includes(type)) err('DOC_TYPE_NOT_ISSUABLE', 'document.document_type', `type ${type} is not in Tabla 3 (RVIE)`);
      if (direction === 'RECEIVED' && !RCE_DOCUMENT_TYPES.includes(type)) err('DOC_TYPE_NOT_RECEIVABLE', 'document.document_type', `type ${type} is not in Tabla 11 (RCE)`);
    }

    // Notas: nunca una venta o compra negativa.
    const isNoteOp = input.operation_type === 'CREDIT_NOTE' || input.operation_type === 'DEBIT_NOTE';
    if (isNoteOp !== NOTE_TYPES.includes(type)) err('NOTE_TYPE_MISMATCH', 'document.document_type', 'credit/debit note operations and note documents (07, 08, 87, 88) must match');
    if (input.operation_type === 'CREDIT_NOTE' && !CREDIT_NOTE_TYPES.includes(type)) err('NOTE_TYPE_MISMATCH', 'document.document_type', 'CREDIT_NOTE requires type 07 or 87');
    if (input.operation_type === 'DEBIT_NOTE' && !DEBIT_NOTE_TYPES.includes(type)) err('NOTE_TYPE_MISMATCH', 'document.document_type', 'DEBIT_NOTE requires type 08 or 88');

    // Serie y número (Tabla 3): 01, 03, 07 y 08 llevan serie de 4 caracteres y número numérico de hasta 8 dígitos mayor a cero.
    if (!/^[A-Za-z0-9]{1,20}$/.test(doc.series ?? '')) err('SERIES_INVALID', 'document.series', 'series must be 1 to 20 alphanumeric characters');
    if (!/^[A-Za-z0-9]{1,20}$/.test(doc.number ?? '')) err('NUMBER_INVALID', 'document.number', 'number must be 1 to 20 alphanumeric characters');
    if (['01', '03', '07', '08'].includes(type)) {
      if ((doc.series ?? '').length !== 4) err('SERIES_LENGTH', 'document.series', `type ${type} requires a 4-character series (Tabla 3)`);
      if (!/^\d{1,8}$/.test(doc.number ?? '') || /^0+$/.test(doc.number ?? '')) err('NUMBER_FORMAT', 'document.number', `type ${type} requires a numeric number of up to 8 digits greater than zero (Tabla 3)`);
    }

    if (!isRealDate(doc.issue_date)) err('DATE_INVALID', 'document.issue_date', 'issue_date must be a valid YYYY-MM-DD date');
    if (doc.due_date !== undefined && (!isRealDate(doc.due_date) || (isRealDate(doc.issue_date) && doc.due_date < doc.issue_date))) err('DATE_INVALID', 'document.due_date', 'due_date must be a valid date on or after issue_date');

    const subtotal = money('document.subtotal', doc.subtotal);
    const igv = money('document.igv', doc.igv ?? '0.00');
    const other = money('document.other_taxes', doc.other_taxes ?? '0.00');
    const total = money('document.total', doc.total);
    operationTotal = total;
    if (subtotal !== undefined && igv !== undefined && other !== undefined && total !== undefined && subtotal + igv + other !== total) {
      err('TOTAL_MISMATCH', 'document.total', 'total must equal subtotal + igv + other_taxes');
    }

    if (doc.lines && doc.lines.length > 0) {
      const parsed = doc.lines.map((l, i) => {
        const s = money(`document.lines[${i}].subtotal`, l.subtotal);
        const g = money(`document.lines[${i}].igv`, l.igv ?? '0.00');
        const t = money(`document.lines[${i}].total`, l.total);
        if (s !== undefined && g !== undefined && t !== undefined && s + g !== t) err('LINE_TOTAL_MISMATCH', `document.lines[${i}].total`, 'line total must equal line subtotal + igv');
        return { s, g, t };
      });
      if (parsed.every((p) => p.s !== undefined && p.g !== undefined && p.t !== undefined)) {
        if (subtotal !== undefined && sum(parsed.map((p) => p.s!)) !== subtotal) err('LINES_SUBTOTAL_MISMATCH', 'document.lines', 'sum of line subtotals must equal document.subtotal');
        if (igv !== undefined && sum(parsed.map((p) => p.g!)) !== igv) err('LINES_IGV_MISMATCH', 'document.lines', 'sum of line igv must equal document.igv');
      }
    }

    // Relación con el documento afectado.
    if (isNoteOp) {
      if (!doc.relations || doc.relations.length === 0) err('NOTE_RELATION_REQUIRED', 'document.relations', 'a credit/debit note must reference at least one affected document');
      (doc.relations ?? []).forEach((r, i) => {
        const f = (name: string) => `document.relations[${i}].${name}`;
        if (!RVIE_DOCUMENT_TYPES.includes(r.related_document_type) && !RCE_DOCUMENT_TYPES.includes(r.related_document_type)) err('RELATED_TYPE_INVALID', f('related_document_type'), 'unknown affected document type');
        if (!r.related_document_series) err('RELATED_SERIES_REQUIRED', f('related_document_series'), 'affected document series is required');
        if (!r.related_document_number) err('RELATED_NUMBER_REQUIRED', f('related_document_number'), 'affected document number is required');
        if (!isRealDate(r.related_issue_date)) err('DATE_INVALID', f('related_issue_date'), 'related_issue_date must be a valid date');
        if (!/^\d{4}(0[1-9]|1[0-2])$/.test(r.original_period ?? '')) err('PERIOD_INVALID', f('original_period'), 'original_period must be YYYYMM');
        else if (isRealDate(r.related_issue_date) && r.original_period !== r.related_issue_date.slice(0, 7).replace('-', '')) {
          warn('PERIOD_DIFFERS_FROM_ISSUE_MONTH', f('original_period'), 'original_period differs from the month of related_issue_date; confirm the period in which the original was registered');
        }
        if (isRealDate(r.related_issue_date) && isRealDate(doc.issue_date) && r.related_issue_date > doc.issue_date) warn('RELATED_AFTER_NOTE', f('related_issue_date'), 'the affected document is dated after the note');
        const base = money(f('affected_base'), r.affected_base);
        const rIgv = money(f('affected_igv'), r.affected_igv ?? '0.00');
        const rTot = money(f('affected_total'), r.affected_total);
        if (base !== undefined && rIgv !== undefined && rTot !== undefined && rTot < base + rIgv) err('AFFECTED_TOTAL_LOW', f('affected_total'), 'affected_total cannot be lower than affected_base + affected_igv');
      });
    } else if (doc.relations && doc.relations.length > 0) {
      err('RELATION_NOT_ALLOWED', 'document.relations', 'only credit/debit notes carry document relations');
    }
  } else {
    if (input.operation_type === 'CREDIT_NOTE' || input.operation_type === 'DEBIT_NOTE') err('NOTE_DOCUMENT_REQUIRED', 'document', 'a credit/debit note requires a document');
    const subtotal = money('subtotal', input.subtotal);
    const tax = money('tax_amount', input.tax_amount ?? '0.00');
    operationTotal = money('total', input.total);
    if (subtotal !== undefined && tax !== undefined && operationTotal !== undefined && operationTotal < subtotal + tax) err('TOTAL_LOW', 'total', 'total cannot be lower than subtotal + tax_amount');
  }

  // Contraparte.
  const cp = input.counterparty;
  if (direction === 'RECEIVED' && doc && !cp) err('COUNTERPARTY_REQUIRED', 'counterparty', 'received documents require a supplier');
  if (cp) {
    if (!cp.id) {
      if (!cp.document_type || !cp.document_number) err('COUNTERPARTY_INVALID', 'counterparty', 'counterparty needs an id or document_type and document_number');
      else {
        for (const m of validateIdentityDocument(cp.document_type, cp.document_number)) err('COUNTERPARTY_DOCUMENT_INVALID', 'counterparty.document_number', m);
        if (cp.document_type === '6' && /^\d{11}$/.test(cp.document_number) && !rucChecksumLooksValid(cp.document_number)) warn('RUC_CHECKSUM', 'counterparty.document_number', 'RUC check digit does not match the usual modulo-11 algorithm (algorithm not verified against an official source)');
      }
      if (!cp.legal_name || cp.legal_name.trim() === '') err('COUNTERPARTY_NAME_REQUIRED', 'counterparty.legal_name', 'legal_name is required for a new counterparty');
    }
    if (direction === undefined && doc) err('DIRECTION_REQUIRED', 'direction', 'direction is required to place the counterparty');
  }

  // Pagos: la fecha de pago es independiente de la fecha de operación.
  let paid = 0n;
  (input.payments ?? []).forEach((p, i) => {
    if (!isRealDate(p.payment_date)) err('DATE_INVALID', `payments[${i}].payment_date`, 'payment_date must be a valid date');
    if (!p.payment_method || p.payment_method.trim() === '') err('PAYMENT_METHOD_REQUIRED', `payments[${i}].payment_method`, 'payment_method is required');
    const a = money(`payments[${i}].amount`, p.amount);
    if (a !== undefined) {
      if (a === 0n) err('PAYMENT_ZERO', `payments[${i}].amount`, 'payment amount must be greater than zero');
      paid += a;
    }
  });
  if (operationTotal !== undefined && paid > operationTotal) err('PAYMENTS_EXCEED_TOTAL', 'payments', 'payments exceed the operation total');

  return issues;
}
