-- Prueba de aislamiento entre empresas (pgTAP). NO EJECUTADA: el entorno de trabajo no tiene PostgreSQL.
-- Uso previsto: `supabase test db` tras `supabase db reset`.
begin;
create extension if not exists pgtap;
select plan(13);

-- Usuarios y empresas de prueba (se insertan como superusuario; RLS no aplica aquí).
insert into auth.users (id, instance_id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'a@test.pe'),
  ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'b@test.pe'),
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'viewer@test.pe');
insert into public.companies (id, ruc, legal_name, tax_regime) values
  ('10000000-0000-0000-0000-00000000000a', '20131312955', 'Empresa A', 'RMT'),
  ('10000000-0000-0000-0000-00000000000b', '20100070970', 'Empresa B', 'RER');
insert into public.company_members (company_id, user_id, role) values
  ('10000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000a1', 'OWNER'),
  ('10000000-0000-0000-0000-00000000000b', '00000000-0000-0000-0000-0000000000b1', 'OWNER'),
  ('10000000-0000-0000-0000-00000000000a', '00000000-0000-0000-0000-0000000000c1', 'VIEWER');
insert into public.suppliers (id, company_id, document_type, document_number, legal_name) values
  ('20000000-0000-0000-0000-00000000000b', '10000000-0000-0000-0000-00000000000b', '6', '20131312955', 'Proveedor de B');

-- Actuar como el usuario A.
set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000a1', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000a1","role":"authenticated"}', true);

select is((select count(*)::int from public.companies), 1, 'A solo ve su empresa');
select is((select count(*)::int from public.suppliers), 0, 'A no ve proveedores de B');
select throws_ok(
  $$ select public.register_operation('10000000-0000-0000-0000-00000000000b', '{"idempotency_key":"x","operation_type":"OTHER","operation_date":"2026-10-01","subtotal":"1.00","total":"1.00"}'::jsonb) $$,
  '42501', 'insufficient privileges', 'A no puede registrar operaciones en B');

-- Operación válida en A, e idempotencia.
select lives_ok(
  $$ select public.register_operation('10000000-0000-0000-0000-00000000000a', '{"idempotency_key":"k1","operation_type":"EXPENSE","operation_date":"2026-10-01","subtotal":"50.00","total":"50.00"}'::jsonb) $$,
  'A registra un gasto sin documento');
select is(
  (select public.register_operation('10000000-0000-0000-0000-00000000000a', '{"idempotency_key":"k1","operation_type":"EXPENSE","operation_date":"2026-10-01","subtotal":"50.00","total":"50.00"}'::jsonb)),
  (select id from public.operations where idempotency_key = 'k1'),
  'repetir la misma clave devuelve la misma operación');
select throws_ok(
  $$ select public.register_operation('10000000-0000-0000-0000-00000000000a', '{"idempotency_key":"k1","operation_type":"EXPENSE","operation_date":"2026-10-01","subtotal":"60.00","total":"60.00"}'::jsonb) $$,
  '22023', 'idempotency_key reused with a different payload', 'la misma clave con otro contenido se rechaza');
select is((select count(*)::int from public.operations), 1, 'no se duplicó la operación');

-- No se puede usar un proveedor de otra empresa (FK compuesta).
select throws_ok(
  $$ insert into public.documents (company_id, direction, document_type, series, number, issue_date, currency, subtotal, igv, total, supplier_id)
     values ('10000000-0000-0000-0000-00000000000a', 'RECEIVED', '01', 'F001', '1', '2026-10-01', 'PEN', 10, 0, 10, '20000000-0000-0000-0000-00000000000b') $$,
  '23503', null, 'no se puede enlazar un proveedor de otra empresa');

-- La auditoría se genera y no se puede alterar.
select ok((select count(*) from public.audit_logs) > 0, 'A ve el rastro de auditoría de su empresa');
select throws_ok($$ delete from public.audit_logs $$, null, null, 'audit_logs no se puede borrar');

-- El usuario VIEWER lee pero no escribe.
select set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', true);
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-0000000000c1","role":"authenticated"}', true);
select is((select count(*)::int from public.operations), 1, 'VIEWER lee las operaciones de su empresa');
select throws_ok(
  $$ select public.register_operation('10000000-0000-0000-0000-00000000000a', '{"idempotency_key":"k2","operation_type":"OTHER","operation_date":"2026-10-01","subtotal":"1.00","total":"1.00"}'::jsonb) $$,
  '42501', 'insufficient privileges', 'VIEWER no puede registrar operaciones');
select is((select count(*)::int from public.audit_logs), 0, 'VIEWER no ve la auditoría');

select * from finish();
rollback;
