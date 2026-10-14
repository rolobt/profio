-- Profio, Fase 1: datos de negocio (sin lógica tributaria).
-- ESTADO: escrito y revisado a mano. NO se ejecutó contra PostgreSQL (no hay motor en el entorno de trabajo).
-- Antes de aplicar en Supabase: correr `supabase db reset` en local y luego supabase/tests/rls_isolation.test.sql.
-- Fuentes de catálogos: Tablas 1, 3, 5 de R.S. 112-2021 (con R.S. 138-2023) y Tabla 11 de R.S. 040-2022.
-- Ver docs/sire-structure.md. Nada aquí decide tratamiento tributario.

-- ---------------------------------------------------------------------------
-- Utilidades
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at() returns trigger
language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ---------------------------------------------------------------------------
-- Tablas de referencia (no son enums: se amplían sin migrar el esquema)
-- ---------------------------------------------------------------------------
create table public.ref_tax_regimes (
  code text primary key,
  name text not null,
  -- V1_TARGET: el motor tributario de V1 los soportará. REVIEW_ONLY: todo va a REQUIRES_REVIEW.
  engine_status text not null check (engine_status in ('V1_TARGET','REVIEW_ONLY')),
  effective_from date,
  effective_to date
);
insert into public.ref_tax_regimes (code, name, engine_status) values
  ('RER',     'Régimen Especial de Renta',        'V1_TARGET'),
  ('RMT',     'Régimen MYPE Tributario',          'V1_TARGET'),
  ('GENERAL', 'Régimen General',                  'REVIEW_ONLY'),
  ('NRUS',    'Nuevo RUS',                        'REVIEW_ONLY'),
  ('OTHER',   'Otro régimen',                     'REVIEW_ONLY');

-- Tipos de documento de identidad: Tabla 1 y Tabla 5 (longitud, tipo, longitud fija o variable, módulo 11).
create table public.ref_identity_doc_types (
  code text primary key,
  description text not null,
  max_length int not null,
  is_numeric boolean not null,
  is_fixed_length boolean not null,
  uses_mod11 boolean not null default false
);
insert into public.ref_identity_doc_types (code, description, max_length, is_numeric, is_fixed_length, uses_mod11) values
  ('0','Doc. trib. no dom. sin RUC',                         15, false, false, false),
  ('1','Documento Nacional de Identidad',                     8, true,  true,  false),
  ('4','Carnet de extranjería',                              12, false, false, false),
  ('6','Registro Único de Contribuyentes',                   11, true,  true,  true),
  ('7','Pasaporte',                                          12, false, false, false),
  ('A','Cédula diplomática de identidad',                    15, true,  true,  false),
  ('B','Documento identidad país residencia no domiciliado', 15, false, false, false),
  ('C','TIN, doc. tributario persona natural',               15, false, false, false),
  ('D','IN, doc. tributario persona jurídica',               15, false, false, false),
  ('E','Tarjeta Andina de Migración',                        15, false, false, false),
  ('F','Permiso Temporal de Permanencia',                    15, false, false, false),
  ('G','Salvoconducto',                                      15, false, false, false);

-- Tipos de comprobante: unión de Tabla 3 (RVIE, ventas) y Tabla 11 (RCE, compras).
-- description solo se llena donde la fuente se leyó (Tabla 3). Tipos solo RCE: descripción pendiente.
create table public.ref_document_types (
  code text primary key check (code ~ '^[0-9]{2}$'),
  description text,
  description_verified boolean not null default false,
  sire_rvie boolean not null default false,   -- aparece en Tabla 3
  sire_rce boolean not null default false,    -- aparece en Tabla 11
  adjustments_only boolean not null default false  -- 48 y 89: solo ajustes de periodos anteriores a agosto de 2021 (138-2023, nota 6)
);
insert into public.ref_document_types (code, description, description_verified, sire_rvie, sire_rce, adjustments_only) values
  ('00','Otros',true,true,true,false),
  ('01','Factura',true,true,true,false),
  ('02',null,false,false,true,false),
  ('03','Boleta de venta',true,true,true,false),
  ('04','Liquidación de compra',true,true,true,false),
  ('05','Boletos de transporte aéreo (BME)',true,true,true,false),
  ('06','Carta de porte aéreo',true,true,true,false),
  ('07','Nota de crédito',true,true,true,false),
  ('08','Nota de débito',true,true,true,false),
  ('10',null,false,false,true,false),
  ('11','Póliza emitida por bolsas de valores',true,true,true,false),
  ('12','Ticket de máquina registradora o ticket POS',true,true,true,false),
  ('13','Documento emitido por bancos, financieras y seguros (SBS)',true,true,true,false),
  ('14','Recibo de servicios públicos',true,true,true,false),
  ('15','Boletos de transporte terrestre urbano de pasajeros',true,true,true,false),
  ('16','Boleto de viaje de transporte interprovincial',true,true,true,false),
  ('17','Documentos de la Iglesia Católica por arrendamiento de inmuebles',true,true,true,false),
  ('18','Documentos de AFP y EPS',true,true,true,false),
  ('19','Boleto por atracciones y espectáculos públicos',true,true,true,false),
  ('21','Conocimiento de embarque (carga marítima)',true,true,true,false),
  ('22',null,false,false,true,false),
  ('23','Pólizas de adjudicación por remate',true,true,true,false),
  ('24','Certificado de pago de regalías PERUPETRO',true,true,true,false),
  ('25',null,false,false,true,false),
  ('27','Seguro Complementario de Trabajo de Riesgo',true,true,true,false),
  ('28','Etiquetas de TUUA',true,true,true,false),
  ('29','Documentos emitidos por COFOPRI',true,true,true,false),
  ('30','Documentos de adquirentes en pagos con tarjeta',true,true,true,false),
  ('32','Documentos de recaudadoras de la Garantía de Red Principal',true,true,true,false),
  ('34','Documento del Operador',true,true,true,false),
  ('35','Documento del Partícipe',true,true,true,false),
  ('36','Recibo de distribución de gas natural',true,true,true,false),
  ('37','Documentos de revisiones técnicas vehiculares',true,true,true,false),
  ('42','Documentos de adquirentes de tarjetas emitidas por ellas mismas',true,true,true,false),
  ('43','Boleto de aviación no regular',true,true,true,false),
  ('44','Billetes de lotería, rifas y apuestas',true,true,true,false),
  ('45','Documentos de centros educativos y culturales',true,true,true,false),
  ('46',null,false,false,true,false),
  ('48','Comprobante de Operaciones (Ley 29972)',true,true,true,true),
  ('49','Constancia de Depósito IVAP',true,true,false,false),
  ('50',null,false,false,true,false),
  ('51',null,false,false,true,false),
  ('52',null,false,false,true,false),
  ('53',null,false,false,true,false),
  ('54',null,false,false,true,false),
  ('55','BVME para transporte ferroviario de pasajeros',true,true,true,false),
  ('56','Comprobante de pago SEAE',true,true,true,false),
  ('64','Documento de servicios con ocasión del transporte aéreo regular',true,true,true,false),
  ('87','Nota de crédito especial',true,true,true,false),
  ('88','Nota de débito especial',true,true,true,false),
  ('89','Nota de Ajuste de Operaciones (Ley 29972)',true,true,true,true),
  ('91',null,false,false,true,false),
  ('96',null,false,false,true,false),
  ('97',null,false,false,true,false),
  ('98',null,false,false,true,false);

-- Tipos de cambio publicados (global, solo lectura para usuarios). Sin datos sembrados: la fuente (SBS) no está verificada.
create table public.exchange_rates (
  id uuid primary key default gen_random_uuid(),
  rate_date date not null,
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  buy numeric(10,6),
  sell numeric(10,6),
  source text not null,
  source_reference text,
  created_at timestamptz not null default now(),
  unique (rate_date, currency, source)
);

-- ---------------------------------------------------------------------------
-- Empresas y miembros
-- ---------------------------------------------------------------------------
create table public.companies (
  id uuid primary key default gen_random_uuid(),
  ruc char(11) not null unique check (ruc ~ '^[0-9]{11}$'),
  legal_name text not null check (length(trim(legal_name)) > 0),
  trade_name text,
  tax_regime text not null references public.ref_tax_regimes (code),
  address text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE')),
  -- Atributos que las reglas SIRE leídas hacen necesarios. NULL = desconocido (las reglas que dependen de ellos van a revisión).
  functional_currency char(3) not null default 'PEN' check (functional_currency in ('PEN','USD')),
  prior_year_income_over_1500_uit boolean,
  is_principal_taxpayer boolean,
  sire_obligation_start_period char(6) check (sire_obligation_start_period ~ '^[0-9]{4}(0[1-9]|1[0-2])$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger companies_updated_at before update on public.companies
  for each row execute function public.set_updated_at();

create table public.company_members (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('OWNER','ADMIN','ACCOUNTANT','OPERATOR','VIEWER')),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INVITED','SUSPENDED')),
  created_at timestamptz not null default now(),
  unique (company_id, user_id)
);
create index company_members_user_idx on public.company_members (user_id) where status = 'ACTIVE';

-- Funciones de pertenencia. SECURITY DEFINER con search_path fijo para evitar recursión de RLS.
create or replace function public.is_company_member(p_company uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_members m
    where m.company_id = p_company and m.user_id = auth.uid() and m.status = 'ACTIVE'
  );
$$;

create or replace function public.has_role(p_company uuid, p_roles text[]) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.company_members m
    where m.company_id = p_company and m.user_id = auth.uid()
      and m.status = 'ACTIVE' and m.role = any (p_roles)
  );
$$;

-- ---------------------------------------------------------------------------
-- Terceros
-- ---------------------------------------------------------------------------
create table public.customers (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  document_type text not null references public.ref_identity_doc_types (code),
  document_number text not null,
  legal_name text not null check (length(trim(legal_name)) > 0),
  address text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, id),
  unique (company_id, document_type, document_number)
);
create table public.suppliers (like public.customers including all);
-- `like ... including all` copia las restricciones unique; se recrean las FK que no se copian.
alter table public.suppliers
  add constraint suppliers_company_fk foreign key (company_id) references public.companies (id) on delete cascade,
  add constraint suppliers_doc_type_fk foreign key (document_type) references public.ref_identity_doc_types (code);

create or replace function public.check_identity_document() returns trigger
language plpgsql as $$
declare r public.ref_identity_doc_types%rowtype;
begin
  select * into r from public.ref_identity_doc_types where code = new.document_type;
  if not found then
    raise exception 'unknown identity document type %', new.document_type using errcode = '23514';
  end if;
  if r.is_numeric and new.document_number !~ '^[0-9]+$' then
    raise exception 'document number for type % must be numeric (Tabla 5)', r.code using errcode = '23514';
  end if;
  if not r.is_numeric and new.document_number !~ '^[A-Za-z0-9]+$' then
    raise exception 'document number for type % must be alphanumeric (Tabla 5)', r.code using errcode = '23514';
  end if;
  if r.is_fixed_length and length(new.document_number) <> r.max_length then
    raise exception 'document number for type % must have % characters (Tabla 5)', r.code, r.max_length using errcode = '23514';
  end if;
  if not r.is_fixed_length and length(new.document_number) > r.max_length then
    raise exception 'document number for type % exceeds % characters (Tabla 5)', r.code, r.max_length using errcode = '23514';
  end if;
  return new;
end $$;

create trigger customers_identity before insert or update on public.customers
  for each row execute function public.check_identity_document();
create trigger suppliers_identity before insert or update on public.suppliers
  for each row execute function public.check_identity_document();
create trigger customers_updated_at before update on public.customers
  for each row execute function public.set_updated_at();
create trigger suppliers_updated_at before update on public.suppliers
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Catálogos de la empresa
-- ---------------------------------------------------------------------------
create table public.products (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  sku text,
  unit text,
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE')),
  created_at timestamptz not null default now(),
  unique (company_id, id)
);
create table public.cash_accounts (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  status text not null default 'ACTIVE' check (status in ('ACTIVE','INACTIVE')),
  created_at timestamptz not null default now(),
  unique (company_id, id)
);

-- ---------------------------------------------------------------------------
-- Comprobantes
-- ---------------------------------------------------------------------------
create table public.documents (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  -- ISSUED: emitido por la empresa (ventas, RVIE). RECEIVED: recibido de un proveedor (compras, RCE).
  direction text not null check (direction in ('ISSUED','RECEIVED')),
  document_type text not null references public.ref_document_types (code),
  series text not null check (series ~ '^[A-Za-z0-9]{1,20}$'),
  number text not null check (number ~ '^[A-Za-z0-9]{1,20}$'),
  issue_date date not null,
  due_date date,
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  exchange_rate numeric(10,6) check (exchange_rate is null or exchange_rate > 0),
  subtotal numeric(14,2) not null check (subtotal >= 0),
  igv numeric(14,2) not null default 0 check (igv >= 0),
  other_taxes numeric(14,2) not null default 0 check (other_taxes >= 0),
  total numeric(14,2) not null check (total >= 0),
  customer_id uuid,
  supplier_id uuid,
  status text not null default 'REGISTERED' check (status in ('DRAFT','REGISTERED','VOIDED')),
  source text not null default 'MANUAL' check (source in ('MANUAL','IMPORT','OCR','SUNAT','API','OTHER')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, customer_id) references public.customers (company_id, id),
  foreign key (company_id, supplier_id) references public.suppliers (company_id, id),
  check (total = subtotal + igv + other_taxes),
  check (direction = 'ISSUED' or supplier_id is not null),
  check (due_date is null or due_date >= issue_date)
);
create unique index documents_issued_uidx
  on public.documents (company_id, document_type, series, number) where direction = 'ISSUED';
create unique index documents_received_uidx
  on public.documents (company_id, supplier_id, document_type, series, number) where direction = 'RECEIVED';
create trigger documents_updated_at before update on public.documents
  for each row execute function public.set_updated_at();

create or replace function public.check_document_direction_type() returns trigger
language plpgsql as $$
declare r public.ref_document_types%rowtype;
begin
  select * into r from public.ref_document_types where code = new.document_type;
  if r.adjustments_only then
    raise exception 'document type % is only valid for adjustments of periods before August 2021', new.document_type
      using errcode = '23514';
  end if;
  if new.direction = 'ISSUED' and not r.sire_rvie then
    raise exception 'document type % is not valid for issued documents (Tabla 3 RVIE)', new.document_type using errcode = '23514';
  end if;
  if new.direction = 'RECEIVED' and not r.sire_rce then
    raise exception 'document type % is not valid for received documents (Tabla 11 RCE)', new.document_type using errcode = '23514';
  end if;
  return new;
end $$;
create trigger documents_direction_type before insert or update of direction, document_type on public.documents
  for each row execute function public.check_document_direction_type();

create table public.document_lines (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  document_id uuid not null,
  description text not null,
  quantity numeric(14,4) not null default 1 check (quantity > 0),
  unit_price numeric(14,6) not null default 0 check (unit_price >= 0),
  subtotal numeric(14,2) not null check (subtotal >= 0),
  igv numeric(14,2) not null default 0 check (igv >= 0),
  total numeric(14,2) not null check (total >= 0),
  tax_category text,            -- sin valores asumidos: lo asigna el motor tributario (Fase 2)
  product_id uuid,
  created_at timestamptz not null default now(),
  foreign key (company_id, document_id) references public.documents (company_id, id) on delete cascade,
  foreign key (company_id, product_id) references public.products (company_id, id),
  check (total = subtotal + igv)
);
create index document_lines_doc_idx on public.document_lines (document_id);

-- ---------------------------------------------------------------------------
-- Operaciones
-- ---------------------------------------------------------------------------
create table public.operations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  operation_type text not null check (operation_type in ('SALE','PURCHASE','EXPENSE','CREDIT_NOTE','DEBIT_NOTE','OTHER')),
  document_id uuid,
  customer_id uuid,
  supplier_id uuid,
  operation_date date not null,
  description text,
  subtotal numeric(14,2) not null check (subtotal >= 0),
  tax_amount numeric(14,2) not null default 0 check (tax_amount >= 0),  -- IGV; los otros tributos solo están en total
  total numeric(14,2) not null check (total >= 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  exchange_rate numeric(10,6) check (exchange_rate is null or exchange_rate > 0),
  payment_status text not null default 'UNPAID' check (payment_status in ('UNPAID','PARTIAL','PAID')),
  status text not null default 'REGISTERED' check (status in ('DRAFT','REGISTERED','VOIDED')),
  idempotency_key text,
  payload_hash text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (company_id, id),
  foreign key (company_id, document_id) references public.documents (company_id, id),
  foreign key (company_id, customer_id) references public.customers (company_id, id),
  foreign key (company_id, supplier_id) references public.suppliers (company_id, id),
  check (customer_id is null or supplier_id is null)
);
create unique index operations_idempotency_uidx
  on public.operations (company_id, idempotency_key) where idempotency_key is not null;
create unique index operations_document_uidx
  on public.operations (company_id, document_id) where document_id is not null;
create index operations_date_idx on public.operations (company_id, operation_date);
create trigger operations_updated_at before update on public.operations
  for each row execute function public.set_updated_at();

-- NC/ND: relación explícita con el documento afectado (no son ventas o compras negativas).
create table public.document_relations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  document_id uuid not null,                  -- la nota
  related_document_id uuid,                   -- documento afectado, si existe en Profio
  related_document_type text not null references public.ref_document_types (code),
  related_document_series text not null,
  related_document_number text not null,
  related_issue_date date not null,
  original_period char(6) not null check (original_period ~ '^[0-9]{4}(0[1-9]|1[0-2])$'),
  affected_base numeric(14,2) not null check (affected_base >= 0),
  affected_igv numeric(14,2) not null default 0 check (affected_igv >= 0),
  affected_total numeric(14,2) not null check (affected_total >= 0),
  reason_code text,                           -- catálogos 09 y 10 de R.S. 097-2012: dato referencial, sin validar
  reason_text text,
  original_operation_id uuid,
  created_at timestamptz not null default now(),
  foreign key (company_id, document_id) references public.documents (company_id, id) on delete cascade,
  foreign key (company_id, related_document_id) references public.documents (company_id, id),
  foreign key (company_id, original_operation_id) references public.operations (company_id, id)
);
create index document_relations_doc_idx on public.document_relations (document_id);

create or replace function public.check_note_document() returns trigger
language plpgsql as $$
declare v_type text;
begin
  select document_type into v_type from public.documents where id = new.document_id;
  if v_type not in ('07','08','87','88') then
    raise exception 'document_relations only apply to credit/debit notes (07, 08, 87, 88), got %', v_type using errcode = '23514';
  end if;
  return new;
end $$;
create trigger document_relations_note before insert on public.document_relations
  for each row execute function public.check_note_document();

-- ---------------------------------------------------------------------------
-- Pagos (fecha de pago separada de la fecha de operación)
-- ---------------------------------------------------------------------------
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references public.companies (id) on delete cascade,
  operation_id uuid not null,
  payment_date date not null,
  amount numeric(14,2) not null check (amount > 0),
  currency char(3) not null check (currency ~ '^[A-Z]{3}$'),
  payment_method text not null check (length(trim(payment_method)) > 0),
  cash_account_id uuid,
  reference text,
  created_at timestamptz not null default now(),
  foreign key (company_id, operation_id) references public.operations (company_id, id),
  foreign key (company_id, cash_account_id) references public.cash_accounts (company_id, id)
);
create index payments_operation_idx on public.payments (operation_id);

create or replace function public.refresh_payment_status() returns trigger
language plpgsql as $$
declare v_op uuid; v_paid numeric(14,2); v_total numeric(14,2); v_cur char(3);
begin
  v_op := coalesce(new.operation_id, old.operation_id);
  select total, currency into v_total, v_cur from public.operations where id = v_op for update;
  if tg_op <> 'DELETE' and new.currency <> v_cur then
    raise exception 'payment currency % differs from operation currency %', new.currency, v_cur using errcode = '23514';
  end if;
  select coalesce(sum(amount), 0) into v_paid from public.payments where operation_id = v_op;
  if v_paid > v_total then
    raise exception 'payments (%) exceed operation total (%)', v_paid, v_total using errcode = '23514';
  end if;
  update public.operations
     set payment_status = case when v_paid = 0 then 'UNPAID' when v_paid < v_total then 'PARTIAL' else 'PAID' end
   where id = v_op;
  return null;
end $$;
create trigger payments_status after insert or update or delete on public.payments
  for each row execute function public.refresh_payment_status();

-- ---------------------------------------------------------------------------
-- Auditoría (inmutable)
-- ---------------------------------------------------------------------------
create table public.audit_logs (
  id bigint generated always as identity primary key,
  company_id uuid not null,
  user_id uuid,
  entity_type text not null,
  entity_id uuid,
  action text not null,
  old_value jsonb,
  new_value jsonb,
  created_at timestamptz not null default now()
);
create index audit_logs_company_idx on public.audit_logs (company_id, created_at desc);

create or replace function public.audit_logs_immutable() returns trigger
language plpgsql as $$
begin
  raise exception 'audit_logs is append-only' using errcode = '42501';
end $$;
create trigger audit_logs_no_change before update or delete on public.audit_logs
  for each row execute function public.audit_logs_immutable();

create or replace function public.audit_row_change() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_old jsonb; v_new jsonb; v_company uuid; v_entity uuid;
begin
  if tg_op = 'DELETE' then v_old := to_jsonb(old);
  elsif tg_op = 'INSERT' then v_new := to_jsonb(new);
  else v_old := to_jsonb(old); v_new := to_jsonb(new); end if;
  if tg_table_name = 'companies' then
    v_company := coalesce(v_new ->> 'id', v_old ->> 'id')::uuid;
  else
    v_company := coalesce(v_new ->> 'company_id', v_old ->> 'company_id')::uuid;
  end if;
  v_entity := coalesce(v_new ->> 'id', v_old ->> 'id')::uuid;
  insert into public.audit_logs (company_id, user_id, entity_type, entity_id, action, old_value, new_value)
  values (v_company, auth.uid(), tg_table_name, v_entity, tg_op, v_old, v_new);
  return null;
end $$;

create trigger audit_companies after insert or update or delete on public.companies
  for each row execute function public.audit_row_change();
create trigger audit_company_members after insert or update or delete on public.company_members
  for each row execute function public.audit_row_change();
create trigger audit_customers after insert or update or delete on public.customers
  for each row execute function public.audit_row_change();
create trigger audit_suppliers after insert or update or delete on public.suppliers
  for each row execute function public.audit_row_change();
create trigger audit_documents after insert or update or delete on public.documents
  for each row execute function public.audit_row_change();
create trigger audit_operations after insert or update or delete on public.operations
  for each row execute function public.audit_row_change();
create trigger audit_document_relations after insert or update or delete on public.document_relations
  for each row execute function public.audit_row_change();
create trigger audit_payments after insert or update or delete on public.payments
  for each row execute function public.audit_row_change();

-- ---------------------------------------------------------------------------
-- RLS: nunca se confía en filtros del frontend
-- ---------------------------------------------------------------------------
alter table public.ref_tax_regimes enable row level security;
alter table public.ref_identity_doc_types enable row level security;
alter table public.ref_document_types enable row level security;
alter table public.exchange_rates enable row level security;
alter table public.companies enable row level security;
alter table public.company_members enable row level security;
alter table public.customers enable row level security;
alter table public.suppliers enable row level security;
alter table public.products enable row level security;
alter table public.cash_accounts enable row level security;
alter table public.documents enable row level security;
alter table public.document_lines enable row level security;
alter table public.operations enable row level security;
alter table public.document_relations enable row level security;
alter table public.payments enable row level security;
alter table public.audit_logs enable row level security;

-- Referencias: lectura para usuarios autenticados, escritura solo con service_role.
create policy ref_tax_regimes_read on public.ref_tax_regimes for select to authenticated using (true);
create policy ref_identity_doc_types_read on public.ref_identity_doc_types for select to authenticated using (true);
create policy ref_document_types_read on public.ref_document_types for select to authenticated using (true);
create policy exchange_rates_read on public.exchange_rates for select to authenticated using (true);

-- Empresas: se crean solo con create_company(); actualizan OWNER y ADMIN; no se borran.
create policy companies_select on public.companies for select to authenticated
  using (public.is_company_member(id));
create policy companies_update on public.companies for update to authenticated
  using (public.has_role(id, array['OWNER','ADMIN']))
  with check (public.has_role(id, array['OWNER','ADMIN']));

-- Miembros: los ven todos los miembros; los administran OWNER y ADMIN.
create policy company_members_select on public.company_members for select to authenticated
  using (public.is_company_member(company_id));
create policy company_members_insert on public.company_members for insert to authenticated
  with check (public.has_role(company_id, array['OWNER','ADMIN']));
create policy company_members_update on public.company_members for update to authenticated
  using (public.has_role(company_id, array['OWNER','ADMIN']))
  with check (public.has_role(company_id, array['OWNER','ADMIN']));
create policy company_members_delete on public.company_members for delete to authenticated
  using (public.has_role(company_id, array['OWNER','ADMIN']));

-- Tablas de negocio: lectura para miembros; escritura OWNER, ADMIN, ACCOUNTANT, OPERATOR.
-- No hay políticas de borrado: los registros se anulan (status = 'VOIDED'), no se eliminan.
do $$
declare t text;
begin
  foreach t in array array['customers','suppliers','products','cash_accounts','documents',
                           'document_lines','operations','document_relations','payments'] loop
    execute format('create policy %I on public.%I for select to authenticated using (public.is_company_member(company_id))',
                   t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.has_role(company_id, array[''OWNER'',''ADMIN'',''ACCOUNTANT'',''OPERATOR'']))',
                   t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (public.has_role(company_id, array[''OWNER'',''ADMIN'',''ACCOUNTANT'',''OPERATOR''])) with check (public.has_role(company_id, array[''OWNER'',''ADMIN'',''ACCOUNTANT'',''OPERATOR'']))',
                   t || '_update', t);
  end loop;
end $$;

-- Auditoría: solo la leen OWNER, ADMIN y ACCOUNTANT. Nadie inserta directamente (lo hace el trigger).
create policy audit_logs_select on public.audit_logs for select to authenticated
  using (public.has_role(company_id, array['OWNER','ADMIN','ACCOUNTANT']));

-- Permisos de tabla: anon sin acceso; authenticated acotado por RLS.
revoke all on all tables in schema public from anon;
revoke all on all tables in schema public from authenticated;
grant select on public.ref_tax_regimes, public.ref_identity_doc_types, public.ref_document_types,
                public.exchange_rates to authenticated;
grant select, update on public.companies to authenticated;
grant select, insert, update, delete on public.company_members to authenticated;
grant select, insert, update on public.customers, public.suppliers, public.products, public.cash_accounts,
                                public.documents, public.document_lines, public.operations,
                                public.document_relations, public.payments to authenticated;
grant select on public.audit_logs to authenticated;

-- ---------------------------------------------------------------------------
-- RPC: crear empresa
-- ---------------------------------------------------------------------------
create or replace function public.create_company(
  p_ruc text, p_legal_name text, p_trade_name text, p_tax_regime text, p_address text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare v_id uuid; v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'authentication required' using errcode = '28000';
  end if;
  insert into public.companies (ruc, legal_name, trade_name, tax_regime, address)
  values (p_ruc, p_legal_name, p_trade_name, p_tax_regime, p_address)
  returning id into v_id;
  insert into public.company_members (company_id, user_id, role) values (v_id, v_uid, 'OWNER');
  return v_id;
end $$;

-- ---------------------------------------------------------------------------
-- RPC: registrar una operación completa de forma atómica e idempotente.
-- SECURITY INVOKER: se aplican las políticas RLS del usuario que llama.
-- Los montos se guardan tal como llegan; la validación de dominio está en src/domain/operations.
-- ---------------------------------------------------------------------------
create or replace function public.register_operation(p_company uuid, p_payload jsonb)
returns uuid
language plpgsql set search_path = public as $$
declare
  v_key text := p_payload ->> 'idempotency_key';
  v_type text := p_payload ->> 'operation_type';
  v_hash text := md5(p_payload::text);
  v_dir text;
  v_existing record;
  v_cp jsonb := p_payload -> 'counterparty';
  v_d jsonb := p_payload -> 'document';
  v_party uuid;
  v_doc uuid;
  v_op uuid;
  v_currency char(3) := coalesce(p_payload ->> 'currency', 'PEN');
  v_fx numeric(10,6) := nullif(p_payload ->> 'exchange_rate', '')::numeric;
  v_subtotal numeric(14,2);
  v_tax numeric(14,2);
  v_total numeric(14,2);
  v_item jsonb;
  v_constraint text;
  v_doc_type text;
begin
  if not public.has_role(p_company, array['OWNER','ADMIN','ACCOUNTANT','OPERATOR']) then
    raise exception 'insufficient privileges' using errcode = '42501';
  end if;
  if v_key is null or length(v_key) = 0 then
    raise exception 'idempotency_key is required' using errcode = '22023';
  end if;

  select id, payload_hash into v_existing from public.operations
   where company_id = p_company and idempotency_key = v_key;
  if found then
    if v_existing.payload_hash is distinct from v_hash then
      raise exception 'idempotency_key reused with a different payload' using errcode = '22023';
    end if;
    return v_existing.id;
  end if;

  v_dir := case v_type
             when 'SALE' then 'ISSUED'
             when 'PURCHASE' then 'RECEIVED'
             when 'EXPENSE' then 'RECEIVED'
             else p_payload ->> 'direction' end;

  if v_d is not null and v_d <> 'null'::jsonb then
    v_doc_type := v_d ->> 'document_type';
    if v_dir is null then
      raise exception 'direction (ISSUED or RECEIVED) is required for operation type %', v_type using errcode = '22023';
    end if;
    -- Una nota de crédito o débito nunca es una venta o compra con signo negativo.
    if (v_type in ('CREDIT_NOTE','DEBIT_NOTE')) <> (v_doc_type in ('07','08','87','88')) then
      raise exception 'credit/debit note operations and note documents (07, 08, 87, 88) must match' using errcode = '23514';
    end if;
    if v_type = 'CREDIT_NOTE' and v_doc_type not in ('07','87') then
      raise exception 'CREDIT_NOTE requires document type 07 or 87' using errcode = '23514';
    end if;
    if v_type = 'DEBIT_NOTE' and v_doc_type not in ('08','88') then
      raise exception 'DEBIT_NOTE requires document type 08 or 88' using errcode = '23514';
    end if;
    if v_type in ('CREDIT_NOTE','DEBIT_NOTE')
       and jsonb_array_length(coalesce(v_d -> 'relations', '[]'::jsonb)) = 0 then
      raise exception 'a credit/debit note requires at least one affected document' using errcode = '23514';
    end if;
  elsif v_type in ('CREDIT_NOTE','DEBIT_NOTE') then
    raise exception 'a credit/debit note requires a document' using errcode = '23514';
  end if;

  begin
    if v_cp is not null and v_cp <> 'null'::jsonb then
      if v_cp ? 'id' then
        v_party := (v_cp ->> 'id')::uuid;
      elsif v_dir = 'ISSUED' then
        insert into public.customers (company_id, document_type, document_number, legal_name, address)
        values (p_company, v_cp ->> 'document_type', v_cp ->> 'document_number', v_cp ->> 'legal_name', v_cp ->> 'address')
        on conflict (company_id, document_type, document_number) do update set updated_at = now()
        returning id into v_party;
      else
        insert into public.suppliers (company_id, document_type, document_number, legal_name, address)
        values (p_company, v_cp ->> 'document_type', v_cp ->> 'document_number', v_cp ->> 'legal_name', v_cp ->> 'address')
        on conflict (company_id, document_type, document_number) do update set updated_at = now()
        returning id into v_party;
      end if;
    end if;

    if v_d is not null and v_d <> 'null'::jsonb then
      insert into public.documents (
        company_id, direction, document_type, series, number, issue_date, due_date, currency, exchange_rate,
        subtotal, igv, other_taxes, total, customer_id, supplier_id, status, source)
      values (
        p_company, v_dir, v_d ->> 'document_type', v_d ->> 'series', v_d ->> 'number',
        (v_d ->> 'issue_date')::date, nullif(v_d ->> 'due_date', '')::date, v_currency, v_fx,
        (v_d ->> 'subtotal')::numeric, coalesce((v_d ->> 'igv')::numeric, 0),
        coalesce((v_d ->> 'other_taxes')::numeric, 0), (v_d ->> 'total')::numeric,
        case when v_dir = 'ISSUED' then v_party end,
        case when v_dir = 'RECEIVED' then v_party end,
        'REGISTERED', coalesce(v_d ->> 'source', 'MANUAL'))
      returning id into v_doc;

      for v_item in select * from jsonb_array_elements(coalesce(v_d -> 'lines', '[]'::jsonb)) loop
        insert into public.document_lines (
          company_id, document_id, description, quantity, unit_price, subtotal, igv, total, tax_category, product_id)
        values (
          p_company, v_doc, v_item ->> 'description', coalesce((v_item ->> 'quantity')::numeric, 1),
          coalesce((v_item ->> 'unit_price')::numeric, 0), (v_item ->> 'subtotal')::numeric,
          coalesce((v_item ->> 'igv')::numeric, 0), (v_item ->> 'total')::numeric,
          v_item ->> 'tax_category', nullif(v_item ->> 'product_id', '')::uuid);
      end loop;

      for v_item in select * from jsonb_array_elements(coalesce(v_d -> 'relations', '[]'::jsonb)) loop
        insert into public.document_relations (
          company_id, document_id, related_document_id, related_document_type, related_document_series,
          related_document_number, related_issue_date, original_period, affected_base, affected_igv,
          affected_total, reason_code, reason_text, original_operation_id)
        values (
          p_company, v_doc, nullif(v_item ->> 'related_document_id', '')::uuid,
          v_item ->> 'related_document_type', v_item ->> 'related_document_series',
          v_item ->> 'related_document_number', (v_item ->> 'related_issue_date')::date,
          v_item ->> 'original_period', (v_item ->> 'affected_base')::numeric,
          coalesce((v_item ->> 'affected_igv')::numeric, 0), (v_item ->> 'affected_total')::numeric,
          v_item ->> 'reason_code', v_item ->> 'reason_text',
          nullif(v_item ->> 'original_operation_id', '')::uuid);
      end loop;

      v_subtotal := (v_d ->> 'subtotal')::numeric;
      v_tax := coalesce((v_d ->> 'igv')::numeric, 0);
      v_total := (v_d ->> 'total')::numeric;
    else
      v_subtotal := (p_payload ->> 'subtotal')::numeric;
      v_tax := coalesce((p_payload ->> 'tax_amount')::numeric, 0);
      v_total := (p_payload ->> 'total')::numeric;
    end if;

    insert into public.operations (
      company_id, operation_type, document_id, customer_id, supplier_id, operation_date, description,
      subtotal, tax_amount, total, currency, exchange_rate, status, idempotency_key, payload_hash)
    values (
      p_company, v_type, v_doc,
      case when v_dir = 'ISSUED' then v_party end,
      case when v_dir = 'RECEIVED' then v_party end,
      (p_payload ->> 'operation_date')::date, p_payload ->> 'description',
      v_subtotal, v_tax, v_total, v_currency, v_fx, 'REGISTERED', v_key, v_hash)
    returning id into v_op;

    for v_item in select * from jsonb_array_elements(coalesce(p_payload -> 'payments', '[]'::jsonb)) loop
      insert into public.payments (
        company_id, operation_id, payment_date, amount, currency, payment_method, cash_account_id, reference)
      values (
        p_company, v_op, (v_item ->> 'payment_date')::date, (v_item ->> 'amount')::numeric, v_currency,
        v_item ->> 'payment_method', nullif(v_item ->> 'cash_account_id', '')::uuid, v_item ->> 'reference');
    end loop;

    return v_op;
  exception when unique_violation then
    get stacked diagnostics v_constraint = constraint_name;
    if v_constraint = 'operations_idempotency_uidx' then
      -- Carrera entre dos llamadas con la misma clave: gana la primera, esta devuelve su resultado.
      select id into v_op from public.operations where company_id = p_company and idempotency_key = v_key;
      if v_op is not null then return v_op; end if;
    end if;
    raise;
  end;
end $$;

revoke all on function public.create_company(text, text, text, text, text) from public, anon;
revoke all on function public.register_operation(uuid, jsonb) from public, anon;
grant execute on function public.create_company(text, text, text, text, text) to authenticated;
grant execute on function public.register_operation(uuid, jsonb) to authenticated;
grant execute on function public.is_company_member(uuid) to authenticated;
grant execute on function public.has_role(uuid, text[]) to authenticated;
