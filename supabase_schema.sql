-- ============================================================
-- LoanManagementSystem — Complete Supabase Database Schema
-- ============================================================
-- Run this entire script in Supabase Dashboard → SQL Editor.
-- Tables are ordered by dependency (run top to bottom).
-- ============================================================


-- ============================================================
-- STEP 1: Create "users" table in public schema
-- ============================================================

CREATE TABLE IF NOT EXISTS public.users (
    id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email           TEXT NOT NULL,
    role            TEXT NOT NULL DEFAULT 'borrower'
        CHECK (role IN ('borrower', 'loan_officer', 'manager', 'admin')),
    full_name       TEXT NOT NULL DEFAULT '',
    mobile_number   TEXT NOT NULL DEFAULT '',
    status          TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'suspended', 'pending')),
    last_login      TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 2: Branches (no FK deps, created first)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.branches (
    branch_id   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    code        TEXT NOT NULL UNIQUE,
    region      TEXT NOT NULL,
    address     TEXT NOT NULL,
    manager_id  UUID,  -- FK added later after managers table exists
    status      TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'inactive', 'closed')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 3: Borrowers
-- ============================================================

CREATE TABLE IF NOT EXISTS public.borrowers (
    borrower_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date_of_birth   DATE NOT NULL,
    pan_number      TEXT NOT NULL,
    aadhaar_number  TEXT NOT NULL,
    kyc_status      TEXT NOT NULL DEFAULT 'pending'
        CHECK (kyc_status IN ('pending', 'in_progress', 'verified', 'rejected')),
    kyc_verified_at TIMESTAMPTZ,
    address         TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);

ALTER TABLE public.borrowers ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 4: Loan Officers
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loan_officers (
    officer_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    employee_code   TEXT NOT NULL UNIQUE,
    branch_id       UUID NOT NULL REFERENCES public.branches(branch_id),
    designation     TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);

ALTER TABLE public.loan_officers ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 5: Managers
-- ============================================================

CREATE TABLE IF NOT EXISTS public.managers (
    manager_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    employee_code   TEXT NOT NULL UNIQUE,
    branch_id       UUID NOT NULL REFERENCES public.branches(branch_id),
    region          TEXT NOT NULL DEFAULT '',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);

ALTER TABLE public.managers ENABLE ROW LEVEL SECURITY;

-- Now add the deferred FK on branches.manager_id → managers.manager_id
ALTER TABLE public.branches
    ADD CONSTRAINT fk_branches_manager
    FOREIGN KEY (manager_id) REFERENCES public.managers(manager_id);


-- ============================================================
-- STEP 6: Admins
-- ============================================================

CREATE TABLE IF NOT EXISTS public.admins (
    admin_id    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    admin_level INT NOT NULL DEFAULT 1,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);

ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 7: Loan Products
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loan_products (
    product_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name                TEXT NOT NULL,
    loan_type           TEXT NOT NULL
        CHECK (loan_type IN ('personal', 'home', 'auto', 'education', 'business')),
    min_amount          NUMERIC(15, 2) NOT NULL DEFAULT 0,
    max_amount          NUMERIC(15, 2) NOT NULL DEFAULT 0,
    min_tenure_months   INT NOT NULL DEFAULT 1,
    max_tenure_months   INT NOT NULL DEFAULT 360,
    base_interest_rate  NUMERIC(5, 2) NOT NULL DEFAULT 0,
    processing_fee_pct  NUMERIC(5, 2) NOT NULL DEFAULT 0,
    eligibility_criteria TEXT NOT NULL DEFAULT '',
    is_active           BOOLEAN NOT NULL DEFAULT true,
    created_by          UUID NOT NULL REFERENCES auth.users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.loan_products ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 8: Loan Applications
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loan_applications (
    application_id  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrower_id     UUID NOT NULL REFERENCES public.borrowers(borrower_id),
    officer_id      UUID REFERENCES public.loan_officers(officer_id),
    product_id      UUID NOT NULL REFERENCES public.loan_products(product_id),
    amount_requested NUMERIC(15, 2) NOT NULL,
    tenure_months   INT NOT NULL,
    purpose         TEXT NOT NULL DEFAULT '',
    status          TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'submitted', 'under_review', 'approved', 'rejected', 'disbursed')),
    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.loan_applications ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 9: Loan Accounts
-- ============================================================

CREATE TABLE IF NOT EXISTS public.loan_accounts (
    account_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id      UUID NOT NULL REFERENCES public.loan_applications(application_id),
    borrower_id         UUID NOT NULL REFERENCES public.borrowers(borrower_id),
    principal_amount    NUMERIC(15, 2) NOT NULL,
    outstanding_balance NUMERIC(15, 2) NOT NULL,
    interest_rate       NUMERIC(5, 2) NOT NULL,
    disbursement_date   DATE,
    closure_date        DATE,
    status              TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'closed', 'defaulted', 'delinquent')),
    next_emi_date       DATE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.loan_accounts ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 10: EMI Schedule
-- ============================================================

CREATE TABLE IF NOT EXISTS public.emi_schedule (
    emi_id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES public.loan_accounts(account_id),
    instalment_no       INT NOT NULL,
    due_date            DATE NOT NULL,
    emi_amount          NUMERIC(15, 2) NOT NULL,
    principal_component NUMERIC(15, 2) NOT NULL,
    interest_component  NUMERIC(15, 2) NOT NULL,
    status              TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'paid', 'overdue', 'bounced')),
    paid_date           DATE,
    paid_amount         NUMERIC(15, 2),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.emi_schedule ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 11: Documents
-- ============================================================

CREATE TABLE IF NOT EXISTS public.documents (
    document_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrower_id     UUID NOT NULL REFERENCES public.borrowers(borrower_id),
    application_id  UUID REFERENCES public.loan_applications(application_id),
    doc_type        TEXT NOT NULL
        CHECK (doc_type IN ('identity_proof', 'address_proof', 'income_proof', 'bank_statement', 'property_document')),
    file_url        TEXT NOT NULL,
    file_name       TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'uploaded'
        CHECK (status IN ('uploaded', 'verified', 'rejected')),
    uploaded_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    verified_by     UUID REFERENCES auth.users(id)
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 12: Credit Scores
-- ============================================================

CREATE TABLE IF NOT EXISTS public.credit_scores (
    score_id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    borrower_id     UUID NOT NULL REFERENCES public.borrowers(borrower_id),
    score           INT NOT NULL,
    risk_category   TEXT NOT NULL DEFAULT 'medium'
        CHECK (risk_category IN ('low', 'medium', 'high')),
    bureau_name     TEXT NOT NULL DEFAULT '',
    assessed_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_current      BOOLEAN NOT NULL DEFAULT true
);

ALTER TABLE public.credit_scores ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 13: Application Workflow
-- ============================================================

CREATE TABLE IF NOT EXISTS public.application_workflow (
    workflow_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id  UUID NOT NULL REFERENCES public.loan_applications(application_id),
    action_by       UUID NOT NULL REFERENCES auth.users(id),
    action          TEXT NOT NULL
        CHECK (action IN ('submitted', 'reviewed', 'approved', 'rejected', 'comment_added', 'disbursed')),
    remarks         TEXT,
    action_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.application_workflow ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 14: Messages
-- ============================================================

CREATE TABLE IF NOT EXISTS public.messages (
    message_id      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id       UUID NOT NULL REFERENCES auth.users(id),
    receiver_id     UUID NOT NULL REFERENCES auth.users(id),
    application_id  UUID REFERENCES public.loan_applications(application_id),
    content         TEXT NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_read         BOOLEAN NOT NULL DEFAULT false
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 15: Notifications
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notifications (
    notification_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id),
    notif_type      TEXT NOT NULL DEFAULT 'push'
        CHECK (notif_type IN ('email', 'sms', 'push')),
    title           TEXT NOT NULL,
    message         TEXT NOT NULL,
    is_read         BOOLEAN NOT NULL DEFAULT false,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 16: Notification Templates
-- ============================================================

CREATE TABLE IF NOT EXISTS public.notification_templates (
    template_id     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    notif_type      TEXT NOT NULL
        CHECK (notif_type IN ('email', 'sms', 'push')),
    title_template  TEXT NOT NULL,
    body_template   TEXT NOT NULL,
    created_by      UUID NOT NULL REFERENCES auth.users(id),
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 17: Reports
-- ============================================================

CREATE TABLE IF NOT EXISTS public.reports (
    report_id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    generated_by    UUID NOT NULL REFERENCES auth.users(id),
    report_type     TEXT NOT NULL
        CHECK (report_type IN ('disbursement', 'collection', 'default_rate', 'performance')),
    period_type     TEXT NOT NULL
        CHECK (period_type IN ('daily', 'weekly', 'monthly', 'yearly')),
    from_date       DATE NOT NULL,
    to_date         DATE NOT NULL,
    format          TEXT NOT NULL DEFAULT 'pdf'
        CHECK (format IN ('pdf', 'csv', 'excel')),
    file_url        TEXT NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 18: Audit Logs
-- ============================================================

CREATE TABLE IF NOT EXISTS public.audit_logs (
    log_id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id),
    action          TEXT NOT NULL,
    entity_type     TEXT NOT NULL,
    entity_id       UUID NOT NULL,
    old_value       JSONB,
    new_value       JSONB,
    ip_address      TEXT NOT NULL DEFAULT '',
    ts              TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;


-- ============================================================
-- STEP 19: Automated Provisioning for Fixed Admin User
-- ============================================================

-- Function to automatically provision the fixed admin user in public tables
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- If the user is the fixed admin email, insert as admin
    IF NEW.email = 'admin@lms.com' THEN
        INSERT INTO public.users (id, email, role, full_name, status)
        VALUES (NEW.id, NEW.email, 'admin', 'System Admin', 'active')
        ON CONFLICT (id) DO NOTHING;

        INSERT INTO public.admins (user_id, admin_level)
        VALUES (NEW.id, 1)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to run on user creation
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- DONE! All 17 new tables + 1 updated table are ready.
-- ============================================================
