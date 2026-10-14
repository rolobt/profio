import { formatMoney, formatRate, parseMoney, parseRate } from '../shared/decimal.ts';
import type { CompanyContext, Issue, Money, RegisterOperationInput } from './types.ts';
import { resolveDirection, validateRegisterOperation } from './validate.ts';

export class OperationValidationError extends Error {
  readonly issues: Issue[];
  constructor(issues: Issue[]) {
    super(`operation rejected: ${issues.filter((i) => i.severity === 'ERROR').map((i) => i.code).join(', ')}`);
    this.name = 'OperationValidationError';
    this.issues = issues;
  }
}

/** Puerto hacia la persistencia. La implementación de Supabase llama a la RPC register_operation. */
export interface OperationGateway {
  registerOperation(companyId: string, payload: Record<string, unknown>): Promise<{ operationId: string }>;
}
export interface CompanyContextProvider {
  getContext(companyId: string): Promise<CompanyContext>;
}

export interface RegisterOperationResult {
  operationId: string;
  warnings: Issue[];
}

const norm = (v: Money | undefined, fn: (x: Money) => bigint, fmt: (x: bigint) => string): string | undefined =>
  v === undefined || v === '' ? undefined : fmt(fn(v));
const m = (v: Money | undefined) => norm(v, parseMoney, formatMoney);

/** Convierte la entrada validada en el payload canónico de la RPC (montos con 2 decimales, tipo de cambio con 6). */
export function toRpcPayload(input: RegisterOperationInput): Record<string, unknown> {
  const doc = input.document;
  return {
    idempotency_key: input.idempotency_key.trim(),
    operation_type: input.operation_type,
    direction: resolveDirection(input),
    operation_date: input.operation_date,
    description: input.description,
    currency: input.currency ?? 'PEN',
    exchange_rate: norm(input.exchange_rate, parseRate, formatRate),
    counterparty: input.counterparty,
    document: doc && {
      ...doc,
      subtotal: m(doc.subtotal),
      igv: m(doc.igv ?? '0.00'),
      other_taxes: m(doc.other_taxes ?? '0.00'),
      total: m(doc.total),
      lines: doc.lines?.map((l) => ({ ...l, subtotal: m(l.subtotal), igv: m(l.igv ?? '0.00'), total: m(l.total) })),
      relations: doc.relations?.map((r) => ({
        ...r, affected_base: m(r.affected_base), affected_igv: m(r.affected_igv ?? '0.00'), affected_total: m(r.affected_total),
      })),
    },
    subtotal: m(input.subtotal),
    tax_amount: input.tax_amount === undefined ? undefined : m(input.tax_amount),
    total: m(input.total),
    payments: input.payments?.map((p) => ({ ...p, amount: m(p.amount) })),
  };
}

export function createOperationService(deps: { gateway: OperationGateway; contexts: CompanyContextProvider }) {
  return {
    async registerOperation(companyId: string, input: RegisterOperationInput): Promise<RegisterOperationResult> {
      const ctx = await deps.contexts.getContext(companyId);
      const issues = validateRegisterOperation(input, ctx);
      if (issues.some((i) => i.severity === 'ERROR')) throw new OperationValidationError(issues);
      const { operationId } = await deps.gateway.registerOperation(companyId, toRpcPayload(input));
      return { operationId, warnings: issues.filter((i) => i.severity === 'WARNING') };
    },
  };
}
