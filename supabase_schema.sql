-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admins (
  admin_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  admin_level integer NOT NULL DEFAULT 1,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT admins_pkey PRIMARY KEY (admin_id),
  CONSTRAINT admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.admins DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.application_workflow (
  workflow_id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL,
  action_by uuid NOT NULL,
  action text NOT NULL CHECK (action = ANY (ARRAY['submitted'::text, 'reviewed'::text, 'approved'::text, 'rejected'::text, 'comment_added'::text, 'disbursed'::text])),
  remarks text,
  action_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT application_workflow_pkey PRIMARY KEY (workflow_id),
  CONSTRAINT application_workflow_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.loan_applications(application_id),
  CONSTRAINT application_workflow_action_by_fkey FOREIGN KEY (action_by) REFERENCES auth.users(id)
);
ALTER TABLE public.application_workflow DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.audit_logs (
  log_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  action text NOT NULL,
  entity_type text NOT NULL,
  entity_id uuid NOT NULL,
  old_value jsonb,
  new_value jsonb,
  ip_address text NOT NULL DEFAULT ''::text,
  ts timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT audit_logs_pkey PRIMARY KEY (log_id),
  CONSTRAINT audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.audit_logs DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.borrowers (
  borrower_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  date_of_birth date NOT NULL,
  pan_number text NOT NULL,
  aadhaar_number text NOT NULL,
  kyc_status text NOT NULL DEFAULT 'pending'::text CHECK (kyc_status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'verified'::text, 'rejected'::text])),
  kyc_verified_at timestamp with time zone,
  address text NOT NULL DEFAULT ''::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT borrowers_pkey PRIMARY KEY (borrower_id),
  CONSTRAINT borrowers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.borrowers DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.branches (
  branch_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  code text NOT NULL UNIQUE,
  region text NOT NULL,
  address text NOT NULL,
  manager_id uuid,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text, 'closed'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT branches_pkey PRIMARY KEY (branch_id),
  CONSTRAINT fk_branches_manager FOREIGN KEY (manager_id) REFERENCES public.managers(manager_id)
);
ALTER TABLE public.branches DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.credit_scores (
  score_id uuid NOT NULL DEFAULT gen_random_uuid(),
  borrower_id uuid NOT NULL,
  score integer NOT NULL,
  risk_category text NOT NULL DEFAULT 'medium'::text CHECK (risk_category = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
  bureau_name text NOT NULL DEFAULT ''::text,
  assessed_at timestamp with time zone NOT NULL DEFAULT now(),
  is_current boolean NOT NULL DEFAULT true,
  CONSTRAINT credit_scores_pkey PRIMARY KEY (score_id),
  CONSTRAINT credit_scores_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(borrower_id)
);
ALTER TABLE public.credit_scores DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.documents (
  document_id uuid NOT NULL DEFAULT gen_random_uuid(),
  borrower_id uuid NOT NULL,
  application_id uuid,
  doc_type text NOT NULL CHECK (doc_type = ANY (ARRAY['identity_proof'::text, 'address_proof'::text, 'income_proof'::text, 'bank_statement'::text, 'property_document'::text])),
  file_url text NOT NULL,
  file_name text NOT NULL,
  status text NOT NULL DEFAULT 'uploaded'::text CHECK (status = ANY (ARRAY['uploaded'::text, 'verified'::text, 'rejected'::text])),
  uploaded_at timestamp with time zone NOT NULL DEFAULT now(),
  verified_by uuid,
  CONSTRAINT documents_pkey PRIMARY KEY (document_id),
  CONSTRAINT documents_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(borrower_id),
  CONSTRAINT documents_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.loan_applications(application_id),
  CONSTRAINT documents_verified_by_fkey FOREIGN KEY (verified_by) REFERENCES auth.users(id)
);
ALTER TABLE public.documents DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.emi_schedule (
  emi_id uuid NOT NULL DEFAULT gen_random_uuid(),
  account_id uuid NOT NULL,
  instalment_no integer NOT NULL,
  due_date date NOT NULL,
  emi_amount numeric NOT NULL,
  principal_component numeric NOT NULL,
  interest_component numeric NOT NULL,
  status text NOT NULL DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'paid'::text, 'overdue'::text, 'bounced'::text])),
  paid_date date,
  paid_amount numeric,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT emi_schedule_pkey PRIMARY KEY (emi_id),
  CONSTRAINT emi_schedule_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.loan_accounts(account_id)
);
ALTER TABLE public.emi_schedule DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.loan_accounts (
  account_id uuid NOT NULL DEFAULT gen_random_uuid(),
  application_id uuid NOT NULL,
  borrower_id uuid NOT NULL,
  principal_amount numeric NOT NULL,
  outstanding_balance numeric NOT NULL,
  interest_rate numeric NOT NULL,
  disbursement_date date,
  closure_date date,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'closed'::text, 'defaulted'::text, 'delinquent'::text])),
  next_emi_date date,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT loan_accounts_pkey PRIMARY KEY (account_id),
  CONSTRAINT loan_accounts_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.loan_applications(application_id),
  CONSTRAINT loan_accounts_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(borrower_id)
);
ALTER TABLE public.loan_accounts DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.loan_applications (
  application_id uuid NOT NULL DEFAULT gen_random_uuid(),
  borrower_id uuid NOT NULL,
  officer_id uuid,
  product_id uuid NOT NULL,
  amount_requested numeric NOT NULL,
  tenure_months integer NOT NULL,
  purpose text NOT NULL DEFAULT ''::text,
  status text NOT NULL DEFAULT 'draft'::text CHECK (status = ANY (ARRAY['draft'::text, 'submitted'::text, 'under_review'::text, 'approved'::text, 'rejected'::text, 'disbursed'::text])),
  submitted_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT loan_applications_pkey PRIMARY KEY (application_id),
  CONSTRAINT loan_applications_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.borrowers(borrower_id),
  CONSTRAINT loan_applications_officer_id_fkey FOREIGN KEY (officer_id) REFERENCES public.loan_officers(officer_id),
  CONSTRAINT loan_applications_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.loan_products(product_id)
);
ALTER TABLE public.loan_applications DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.loan_officers (
  officer_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  employee_code text NOT NULL UNIQUE,
  branch_id uuid NOT NULL,
  designation text NOT NULL DEFAULT ''::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT loan_officers_pkey PRIMARY KEY (officer_id),
  CONSTRAINT loan_officers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT loan_officers_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id)
);
ALTER TABLE public.loan_officers DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.loan_products (
  product_id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  loan_type text NOT NULL CHECK (loan_type = ANY (ARRAY['personal'::text, 'home'::text, 'auto'::text, 'education'::text, 'business'::text])),
  min_amount numeric NOT NULL DEFAULT 0,
  max_amount numeric NOT NULL DEFAULT 0,
  min_tenure_months integer NOT NULL DEFAULT 1,
  max_tenure_months integer NOT NULL DEFAULT 360,
  base_interest_rate numeric NOT NULL DEFAULT 0,
  processing_fee_pct numeric NOT NULL DEFAULT 0,
  eligibility_criteria text NOT NULL DEFAULT ''::text,
  is_active boolean NOT NULL DEFAULT true,
  created_by uuid NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT loan_products_pkey PRIMARY KEY (product_id),
  CONSTRAINT loan_products_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
ALTER TABLE public.loan_products DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.managers (
  manager_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE,
  employee_code text NOT NULL UNIQUE,
  branch_id uuid NOT NULL,
  region text NOT NULL DEFAULT ''::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT managers_pkey PRIMARY KEY (manager_id),
  CONSTRAINT managers_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT managers_branch_id_fkey FOREIGN KEY (branch_id) REFERENCES public.branches(branch_id)
);
ALTER TABLE public.managers DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.messages (
  message_id uuid NOT NULL DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL,
  receiver_id uuid NOT NULL,
  application_id uuid,
  content text NOT NULL,
  sent_at timestamp with time zone NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false,
  CONSTRAINT messages_pkey PRIMARY KEY (message_id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id),
  CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES auth.users(id),
  CONSTRAINT messages_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.loan_applications(application_id)
);
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.notification_templates (
  template_id uuid NOT NULL DEFAULT gen_random_uuid(),
  notif_type text NOT NULL CHECK (notif_type = ANY (ARRAY['email'::text, 'sms'::text, 'push'::text])),
  title_template text NOT NULL,
  body_template text NOT NULL,
  created_by uuid NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notification_templates_pkey PRIMARY KEY (template_id),
  CONSTRAINT notification_templates_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id)
);
ALTER TABLE public.notification_templates DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.notifications (
  notification_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  notif_type text NOT NULL DEFAULT 'push'::text CHECK (notif_type = ANY (ARRAY['email'::text, 'sms'::text, 'push'::text])),
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (notification_id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.push_device_tokens (
  token_id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  device_token text NOT NULL,
  platform text NOT NULL DEFAULT 'ios'::text CHECK (platform = ANY (ARRAY['ios'::text, 'android'::text, 'web'::text])),
  app_bundle_id text NOT NULL DEFAULT ''::text,
  device_name text NOT NULL DEFAULT ''::text,
  is_active boolean NOT NULL DEFAULT true,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT push_device_tokens_pkey PRIMARY KEY (token_id),
  CONSTRAINT push_device_tokens_unique UNIQUE (user_id, device_token),
  CONSTRAINT push_device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
ALTER TABLE public.push_device_tokens DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  full_name text NOT NULL DEFAULT ''::text,
  email text NOT NULL DEFAULT ''::text,
  mobile_number text NOT NULL DEFAULT ''::text,
  alternate_number text,
  date_of_birth timestamp with time zone,
  gender text NOT NULL DEFAULT ''::text,
  marital_status text NOT NULL DEFAULT ''::text,
  nationality text NOT NULL DEFAULT ''::text,
  aadhaar_number text NOT NULL DEFAULT ''::text,
  pan_number text NOT NULL DEFAULT ''::text,
  is_email_verified boolean NOT NULL DEFAULT false,
  is_phone_verified boolean NOT NULL DEFAULT false,
  current_address jsonb NOT NULL DEFAULT '{}'::jsonb,
  permanent_address jsonb NOT NULL DEFAULT '{}'::jsonb,
  employment jsonb NOT NULL DEFAULT '{}'::jsonb,
  income jsonb NOT NULL DEFAULT '{}'::jsonb,
  bank_details jsonb NOT NULL DEFAULT '{}'::jsonb,
  kyc_verification jsonb NOT NULL DEFAULT '{}'::jsonb,
  loan_overview jsonb NOT NULL DEFAULT '{}'::jsonb,
  profile_image_data text,
  occupation text NOT NULL DEFAULT ''::text,
  industry text NOT NULL DEFAULT ''::text,
  years_of_experience integer NOT NULL DEFAULT 0,
  has_existing_bank_account boolean NOT NULL DEFAULT false,
  existing_customer_id text,
  preferred_branch text NOT NULL DEFAULT ''::text,
  existing_loans_count integer NOT NULL DEFAULT 0,
  existing_credit_cards_count integer NOT NULL DEFAULT 0,
  banking_relationship_duration text NOT NULL DEFAULT ''::text,
  average_monthly_balance numeric NOT NULL DEFAULT 0,
  emergency_contact_name text NOT NULL DEFAULT ''::text,
  emergency_contact_number text NOT NULL DEFAULT ''::text,
  emergency_contact_alternate_number text NOT NULL DEFAULT ''::text,
  emergency_contact_address text NOT NULL DEFAULT ''::text,
  emergency_contact_relationship text NOT NULL DEFAULT ''::text,
  nominee_name text NOT NULL DEFAULT ''::text,
  nominee_relationship text NOT NULL DEFAULT ''::text,
  is_onboarding_completed boolean NOT NULL DEFAULT false,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES public.users(id)
);
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.reports (
  report_id uuid NOT NULL DEFAULT gen_random_uuid(),
  generated_by uuid NOT NULL,
  report_type text NOT NULL CHECK (report_type = ANY (ARRAY['disbursement'::text, 'collection'::text, 'default_rate'::text, 'performance'::text])),
  period_type text NOT NULL CHECK (period_type = ANY (ARRAY['daily'::text, 'weekly'::text, 'monthly'::text, 'yearly'::text])),
  from_date date NOT NULL,
  to_date date NOT NULL,
  format text NOT NULL DEFAULT 'pdf'::text CHECK (format = ANY (ARRAY['pdf'::text, 'csv'::text, 'excel'::text])),
  file_url text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT reports_pkey PRIMARY KEY (report_id),
  CONSTRAINT reports_generated_by_fkey FOREIGN KEY (generated_by) REFERENCES auth.users(id)
);
ALTER TABLE public.reports DISABLE ROW LEVEL SECURITY;
CREATE TABLE public.users (
  id uuid NOT NULL,
  email text NOT NULL,
  role text NOT NULL DEFAULT 'borrower'::text CHECK (role = ANY (ARRAY['borrower'::text, 'loan_officer'::text, 'manager'::text, 'admin'::text])),
  full_name text NOT NULL DEFAULT ''::text,
  mobile_number text NOT NULL DEFAULT ''::text,
  status text NOT NULL DEFAULT 'active'::text CHECK (status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text, 'pending'::text])),
  last_login timestamp with time zone,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT users_pkey PRIMARY KEY (id),
  CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  date timestamp with time zone NOT NULL DEFAULT now(),
  amount numeric NOT NULL,
  type text NOT NULL,
  reference_no text NOT NULL UNIQUE,
  bank_account_id uuid,
  borrower_id uuid NOT NULL,
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT transactions_borrower_id_fkey FOREIGN KEY (borrower_id) REFERENCES public.users(id)
);
ALTER TABLE public.transactions DISABLE ROW LEVEL SECURITY;
