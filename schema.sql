-- Kaizen CAPA schema
-- SQLite-compatible table structures.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS employees (
    employee_id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_number TEXT UNIQUE,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE,
    department TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS item_numbers (
    item_number_id INTEGER PRIMARY KEY AUTOINCREMENT,
    item_number TEXT NOT NULL UNIQUE,
    description TEXT,
    model_product_family TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_name TEXT NOT NULL UNIQUE,
    contact_name TEXT,
    contact_email TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_name TEXT NOT NULL UNIQUE,
    contact_name TEXT,
    contact_email TEXT,
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS kaizen_details (
    kaizen_id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Corrective Action', 'Preventive Action')),
    category TEXT NOT NULL CHECK (
        category IN (
            'Product Quality',
            'Process',
            'Documentation',
            'Equipment',
            'Supplier',
            'Customer Complaint',
            'Audit',
            'Finding',
            'Training',
            'Safety',
            'Regulatory'
        )
    ),
    origin_type TEXT NOT NULL CHECK (
        origin_type IN (
            'Internal Audit',
            'External Audit',
            'Customer Complaint',
            'Supplier Complaint',
            'Incoming Inspection',
            'In-Process Inspection',
            'Final Inspection',
            'Field Failure',
            'Management Review',
            'Risk Assessment'
        )
    ),
    originator_id INTEGER NOT NULL,
    priority TEXT NOT NULL CHECK (priority IN ('High', 'Low')),
    importance TEXT NOT NULL CHECK (importance IN ('High', 'Low')),
    date_requested DATE NOT NULL,
    date_updated DATE,
    model_product_family TEXT,
    item_number_id INTEGER,
    status TEXT NOT NULL DEFAULT 'Active' CHECK (status IN ('Active', 'Resolved', 'Closed', 'Void')),
    date_closed DATE,
    customer_id INTEGER,
    supplier_id INTEGER,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    d0_reported_condition_symptoms TEXT,
    d2_problem_statement TEXT,
    d3_interim_corrective_action TEXT,

    FOREIGN KEY (originator_id) REFERENCES employees(employee_id),
    FOREIGN KEY (item_number_id) REFERENCES item_numbers(item_number_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
    CHECK (
        (status = 'Closed' AND date_closed IS NOT NULL)
        OR (status <> 'Closed')
    )
);

CREATE TABLE IF NOT EXISTS kaizen_team_members (
    kaizen_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    role TEXT,
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (kaizen_id, employee_id),
    FOREIGN KEY (kaizen_id) REFERENCES kaizen_details(kaizen_id) ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);
CREATE TABLE IF NOT EXISTS kaizen_problem_statement_attachments (
    attachment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    kaizen_id INTEGER NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    content_type TEXT,
    uploaded_by_id INTEGER,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kaizen_id) REFERENCES kaizen_details(kaizen_id) ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS kaizen_containment_activities (
    containment_activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
    kaizen_id INTEGER NOT NULL,
    item_number_id INTEGER,
    location TEXT,
    quantity INTEGER CHECK (quantity IS NULL OR quantity >= 0),
    lot_number TEXT,
    total_accepted INTEGER CHECK (total_accepted IS NULL OR total_accepted >= 0),
    total_rejected INTEGER CHECK (total_rejected IS NULL OR total_rejected >= 0),
    disposition TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kaizen_id) REFERENCES kaizen_details(kaizen_id) ON DELETE CASCADE,
    FOREIGN KEY (item_number_id) REFERENCES item_numbers(item_number_id),
    CHECK (
        quantity IS NULL
        OR total_accepted IS NULL
        OR total_rejected IS NULL
        OR quantity = total_accepted + total_rejected
    )
);

CREATE TABLE IF NOT EXISTS kaizen_root_cause_corrective_actions (
    root_cause_corrective_action_id INTEGER PRIMARY KEY AUTOINCREMENT,
    kaizen_id INTEGER NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('Detection', 'Occurrence')),
    root_cause TEXT NOT NULL,
    corrective_action TEXT,
    responsible_id INTEGER,
    expected_date DATE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kaizen_id) REFERENCES kaizen_details(kaizen_id) ON DELETE CASCADE,
    FOREIGN KEY (responsible_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS kaizen_root_cause_corrective_action_attachments (
    attachment_id INTEGER PRIMARY KEY AUTOINCREMENT,
    root_cause_corrective_action_id INTEGER NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    content_type TEXT,
    uploaded_by_id INTEGER,
    uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (root_cause_corrective_action_id)
        REFERENCES kaizen_root_cause_corrective_actions(root_cause_corrective_action_id)
        ON DELETE CASCADE,
    FOREIGN KEY (uploaded_by_id) REFERENCES employees(employee_id)
);

CREATE TABLE IF NOT EXISTS kaizen_verification_activities (
    verification_activity_id INTEGER PRIMARY KEY AUTOINCREMENT,
    kaizen_id INTEGER NOT NULL,
    validation_activity TEXT NOT NULL,
    responsible_id INTEGER,
    due_date DATE,
    validated_date DATE,
    comments TEXT,
    status TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (kaizen_id) REFERENCES kaizen_details(kaizen_id) ON DELETE CASCADE,
    FOREIGN KEY (responsible_id) REFERENCES employees(employee_id)
);

CREATE INDEX IF NOT EXISTS idx_kaizen_details_status
    ON kaizen_details(status);

CREATE INDEX IF NOT EXISTS idx_kaizen_details_originator
    ON kaizen_details(originator_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_details_item_number
    ON kaizen_details(item_number_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_team_members_employee
    ON kaizen_team_members(employee_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_problem_statement_attachments_kaizen
    ON kaizen_problem_statement_attachments(kaizen_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_containment_activities_kaizen
    ON kaizen_containment_activities(kaizen_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_root_cause_corrective_actions_kaizen
    ON kaizen_root_cause_corrective_actions(kaizen_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_root_cause_corrective_actions_responsible
    ON kaizen_root_cause_corrective_actions(responsible_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_verification_activities_kaizen
    ON kaizen_verification_activities(kaizen_id);

CREATE INDEX IF NOT EXISTS idx_kaizen_verification_activities_responsible
    ON kaizen_verification_activities(responsible_id);
