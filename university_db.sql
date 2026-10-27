
BEGIN;

-- 1. Organization

CREATE TABLE faculty (
    faculty_id      SERIAL,
    name            VARCHAR(150) NOT NULL,
    code            VARCHAR(20)  NOT NULL,
    established_at  DATE,
    CONSTRAINT pk_faculty PRIMARY KEY (faculty_id),
    CONSTRAINT uq_faculty_code UNIQUE (code)
);

CREATE TABLE department (
    department_id   SERIAL,
    faculty_id      INT          NOT NULL,
    name            VARCHAR(150) NOT NULL,
    code            VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_department PRIMARY KEY (department_id),
    CONSTRAINT uq_department_code UNIQUE (code),
    CONSTRAINT fk_department_faculty FOREIGN KEY (faculty_id)
        REFERENCES faculty (faculty_id) ON DELETE RESTRICT
);

-- 2. Staff (supertype) and its subtypes

CREATE TABLE staff (
    staff_id        SERIAL,
    faculty_id      INT          NOT NULL,
    department_id   INT,
    full_name       VARCHAR(150) NOT NULL,
    national_id     CHAR(14)     NOT NULL,
    email           VARCHAR(150) NOT NULL,
    phone           VARCHAR(20),
    staff_type      VARCHAR(20)  NOT NULL,
    hire_date       DATE         NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_staff PRIMARY KEY (staff_id),
    CONSTRAINT uq_staff_national_id UNIQUE (national_id),
    CONSTRAINT uq_staff_email UNIQUE (email),
    CONSTRAINT ck_staff_type CHECK (staff_type IN ('PROFESSOR', 'TA', 'EMPLOYEE')),
    CONSTRAINT ck_staff_national_id CHECK (national_id ~ '^[0-9]{14}$'),
    CONSTRAINT fk_staff_faculty FOREIGN KEY (faculty_id)
        REFERENCES faculty (faculty_id) ON DELETE RESTRICT,
    CONSTRAINT fk_staff_department FOREIGN KEY (department_id)
        REFERENCES department (department_id) ON DELETE SET NULL
);

CREATE TABLE professor (
    staff_id        INT,
    academic_rank   VARCHAR(50)  NOT NULL,
    specialization  VARCHAR(100),
    CONSTRAINT pk_professor PRIMARY KEY (staff_id),
    CONSTRAINT fk_professor_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE CASCADE
);

CREATE TABLE teaching_assistant (
    staff_id        INT,
    degree_status   VARCHAR(50),
    CONSTRAINT pk_teaching_assistant PRIMARY KEY (staff_id),
    CONSTRAINT fk_ta_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE CASCADE
);

CREATE TABLE employee (
    staff_id        INT,
    job_title       VARCHAR(100) NOT NULL,
    office          VARCHAR(50),
    CONSTRAINT pk_employee PRIMARY KEY (staff_id),
    CONSTRAINT fk_employee_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE CASCADE
);

CREATE TABLE position (
    position_id     SERIAL,
    title           VARCHAR(100) NOT NULL,
    scope           VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_position PRIMARY KEY (position_id),
    CONSTRAINT uq_position_title UNIQUE (title),
    CONSTRAINT ck_position_scope CHECK (scope IN ('UNIVERSITY', 'FACULTY', 'DEPARTMENT'))
);

CREATE TABLE staff_position (
    staff_id        INT  NOT NULL,
    position_id     INT  NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,
    faculty_id      INT,
    department_id   INT,
    CONSTRAINT pk_staff_position PRIMARY KEY (staff_id, position_id, start_date),
    CONSTRAINT ck_staff_position_dates CHECK (end_date IS NULL OR end_date > start_date),
    CONSTRAINT fk_staff_position_staff FOREIGN KEY (staff_id)
        REFERENCES staff (staff_id) ON DELETE CASCADE,
    CONSTRAINT fk_staff_position_position FOREIGN KEY (position_id)
        REFERENCES position (position_id) ON DELETE RESTRICT,
    CONSTRAINT fk_staff_position_faculty FOREIGN KEY (faculty_id)
        REFERENCES faculty (faculty_id) ON DELETE RESTRICT,
    CONSTRAINT fk_staff_position_department FOREIGN KEY (department_id)
        REFERENCES department (department_id) ON DELETE RESTRICT
);

CREATE TABLE professor_ta (
    professor_id    INT  NOT NULL,
    ta_id           INT  NOT NULL,
    start_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    role            VARCHAR(50),
    CONSTRAINT pk_professor_ta PRIMARY KEY (professor_id, ta_id),
    CONSTRAINT fk_professor_ta_professor FOREIGN KEY (professor_id)
        REFERENCES professor (staff_id) ON DELETE CASCADE,
    CONSTRAINT fk_professor_ta_ta FOREIGN KEY (ta_id)
        REFERENCES teaching_assistant (staff_id) ON DELETE CASCADE
);

-- 3. Academic

CREATE TABLE course (
    course_id       SERIAL,
    department_id   INT          NOT NULL,
    code            VARCHAR(20)  NOT NULL,
    title           VARCHAR(150) NOT NULL,
    credit_hours    SMALLINT     NOT NULL,
    level           SMALLINT     NOT NULL,
    CONSTRAINT pk_course PRIMARY KEY (course_id),
    CONSTRAINT uq_course_code UNIQUE (code),
    CONSTRAINT ck_course_credit_hours CHECK (credit_hours BETWEEN 1 AND 6),
    CONSTRAINT ck_course_level CHECK (level BETWEEN 1 AND 5),
    CONSTRAINT fk_course_department FOREIGN KEY (department_id)
        REFERENCES department (department_id) ON DELETE RESTRICT
);

CREATE TABLE course_prerequisite (
    course_id       INT NOT NULL,
    prerequisite_id INT NOT NULL,
    CONSTRAINT pk_course_prerequisite PRIMARY KEY (course_id, prerequisite_id),
    CONSTRAINT ck_course_prerequisite_not_self CHECK (course_id <> prerequisite_id),
    CONSTRAINT fk_prereq_course FOREIGN KEY (course_id)
        REFERENCES course (course_id) ON DELETE CASCADE,
    CONSTRAINT fk_prereq_prerequisite FOREIGN KEY (prerequisite_id)
        REFERENCES course (course_id) ON DELETE CASCADE
);

CREATE TABLE semester (
    semester_id     SERIAL,
    academic_year   VARCHAR(9)  NOT NULL,
    term            VARCHAR(10) NOT NULL,
    start_date      DATE        NOT NULL,
    end_date        DATE        NOT NULL,
    CONSTRAINT pk_semester PRIMARY KEY (semester_id),
    CONSTRAINT uq_semester_year_term UNIQUE (academic_year, term),
    CONSTRAINT ck_semester_term CHECK (term IN ('FALL', 'SPRING', 'SUMMER')),
    CONSTRAINT ck_semester_year CHECK (academic_year ~ '^[0-9]{4}/[0-9]{4}$'),
    CONSTRAINT ck_semester_dates CHECK (end_date > start_date)
);

CREATE TABLE section (
    section_id      SERIAL,
    course_id       INT         NOT NULL,
    semester_id     INT         NOT NULL,
    professor_id    INT         NOT NULL,
    section_code    VARCHAR(10) NOT NULL,
    capacity        SMALLINT    NOT NULL,
    CONSTRAINT pk_section PRIMARY KEY (section_id),
    CONSTRAINT uq_section_code UNIQUE (course_id, semester_id, section_code),
    CONSTRAINT ck_section_capacity CHECK (capacity > 0),
    CONSTRAINT fk_section_course FOREIGN KEY (course_id)
        REFERENCES course (course_id) ON DELETE RESTRICT,
    CONSTRAINT fk_section_semester FOREIGN KEY (semester_id)
        REFERENCES semester (semester_id) ON DELETE RESTRICT,
    CONSTRAINT fk_section_professor FOREIGN KEY (professor_id)
        REFERENCES professor (staff_id) ON DELETE RESTRICT
);

CREATE TABLE section_ta (
    section_id      INT NOT NULL,
    ta_id           INT NOT NULL,
    CONSTRAINT pk_section_ta PRIMARY KEY (section_id, ta_id),
    CONSTRAINT fk_section_ta_section FOREIGN KEY (section_id)
        REFERENCES section (section_id) ON DELETE CASCADE,
    CONSTRAINT fk_section_ta_ta FOREIGN KEY (ta_id)
        REFERENCES teaching_assistant (staff_id) ON DELETE CASCADE
);

-- 4. Students

CREATE TABLE student (
    student_id      SERIAL,
    department_id   INT          NOT NULL,
    advisor_id      INT,
    full_name       VARCHAR(150) NOT NULL,
    national_id     CHAR(14)     NOT NULL,
    email           VARCHAR(150) NOT NULL,
    level           SMALLINT     NOT NULL DEFAULT 1,
    status          VARCHAR(20)  NOT NULL DEFAULT 'ACTIVE',
    enrollment_date DATE         NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT pk_student PRIMARY KEY (student_id),
    CONSTRAINT uq_student_national_id UNIQUE (national_id),
    CONSTRAINT uq_student_email UNIQUE (email),
    CONSTRAINT ck_student_level CHECK (level BETWEEN 1 AND 5),
    CONSTRAINT ck_student_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'GRADUATED', 'WITHDRAWN')),
    CONSTRAINT ck_student_national_id CHECK (national_id ~ '^[0-9]{14}$'),
    CONSTRAINT fk_student_department FOREIGN KEY (department_id)
        REFERENCES department (department_id) ON DELETE RESTRICT,
    CONSTRAINT fk_student_advisor FOREIGN KEY (advisor_id)
        REFERENCES professor (staff_id) ON DELETE SET NULL
);

CREATE TABLE enrollment (
    student_id      INT           NOT NULL,
    section_id      INT           NOT NULL,
    enrolled_at     DATE          NOT NULL DEFAULT CURRENT_DATE,
    grade           NUMERIC(5, 2),
    letter_grade    VARCHAR(2),
    status          VARCHAR(20)   NOT NULL DEFAULT 'ENROLLED',
    CONSTRAINT pk_enrollment PRIMARY KEY (student_id, section_id),
    CONSTRAINT ck_enrollment_grade CHECK (grade BETWEEN 0 AND 100),
    CONSTRAINT ck_enrollment_letter CHECK (letter_grade IN ('A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C', 'C-', 'D+', 'D', 'F')),
    CONSTRAINT ck_enrollment_status CHECK (status IN ('ENROLLED', 'DROPPED', 'COMPLETED', 'FAILED')),
    CONSTRAINT fk_enrollment_student FOREIGN KEY (student_id)
        REFERENCES student (student_id) ON DELETE CASCADE,
    CONSTRAINT fk_enrollment_section FOREIGN KEY (section_id)
        REFERENCES section (section_id) ON DELETE RESTRICT
);

-- 5. Indexes on foreign keys used in joins
-- (primary keys and unique columns are indexed automatically)

CREATE INDEX idx_department_faculty   ON department (faculty_id);
CREATE INDEX idx_staff_faculty        ON staff (faculty_id);
CREATE INDEX idx_staff_department     ON staff (department_id);
CREATE INDEX idx_course_department    ON course (department_id);
CREATE INDEX idx_section_semester     ON section (semester_id);
CREATE INDEX idx_section_professor    ON section (professor_id);
CREATE INDEX idx_student_department   ON student (department_id);
CREATE INDEX idx_student_advisor      ON student (advisor_id);
CREATE INDEX idx_enrollment_section   ON enrollment (section_id);
CREATE INDEX idx_section_ta_ta        ON section_ta (ta_id);
CREATE INDEX idx_professor_ta_ta      ON professor_ta (ta_id);

-- 6. Table descriptions (visible in pgAdmin under each table's properties)

COMMENT ON TABLE faculty             IS 'A faculty of the university';
COMMENT ON TABLE department          IS 'A department inside a faculty';
COMMENT ON TABLE staff               IS 'Every university worker; shared data for all staff types';
COMMENT ON TABLE professor           IS 'Professor-specific data, one-to-one with staff';
COMMENT ON TABLE teaching_assistant  IS 'Teaching assistant-specific data, one-to-one with staff';
COMMENT ON TABLE employee            IS 'Administrative employee-specific data, one-to-one with staff';
COMMENT ON TABLE position            IS 'Administrative positions such as dean or head of department';
COMMENT ON TABLE staff_position      IS 'History of positions held by staff';
COMMENT ON TABLE professor_ta        IS 'Which teaching assistants work with which professors';
COMMENT ON TABLE course              IS 'A course offered by a department, independent of semester';
COMMENT ON TABLE course_prerequisite IS 'Courses that must be completed before another course';
COMMENT ON TABLE semester            IS 'An academic term';
COMMENT ON TABLE section             IS 'A course offered in a specific semester by a specific professor';
COMMENT ON TABLE section_ta          IS 'Teaching assistants assigned to a section';
COMMENT ON TABLE student             IS 'A student, belongs to one department, optionally has an advisor';
COMMENT ON TABLE enrollment          IS 'A student registered in a section, with grade and status';

COMMIT;
