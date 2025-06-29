-- ========================================
-- TABLE CREATION (COMMENTED FOR SAFETY)
-- ========================================
-- CREATE TABLE Customers (
--   CustomerID NUMBER PRIMARY KEY,
--   Name VARCHAR2(100),
--   DOB DATE,
--   Balance NUMBER,
--   LastModified DATE
-- );

-- CREATE TABLE Accounts (
--   AccountID NUMBER PRIMARY KEY,
--   CustomerID NUMBER,
--   AccountType VARCHAR2(20),
--   Balance NUMBER,
--   LastModified DATE,
--   FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
-- );

-- CREATE TABLE Transactions (
--   TransactionID NUMBER PRIMARY KEY,
--   AccountID NUMBER,
--   TransactionDate DATE,
--   Amount NUMBER,
--   TransactionType VARCHAR2(10),
--   FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
-- );

-- CREATE TABLE Loans (
--   LoanID NUMBER PRIMARY KEY,
--   CustomerID NUMBER,
--   LoanAmount NUMBER,
--   InterestRate NUMBER,
--   StartDate DATE,
--   EndDate DATE,
--   FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
-- );

-- CREATE TABLE Employees (
--   EmployeeID NUMBER PRIMARY KEY,
--   Name VARCHAR2(100),
--   Position VARCHAR2(50),
--   Salary NUMBER,
--   Department VARCHAR2(50),
--   HireDate DATE
-- );

-- ========================================
-- SAMPLE DATA INSERTION
-- ========================================
INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (1, 'John Doe', TO_DATE('1985-05-15', 'YYYY-MM-DD'), 1000, SYSDATE);

INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
VALUES (2, 'Jane Smith', TO_DATE('1990-07-20', 'YYYY-MM-DD'), 1500, SYSDATE);

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
VALUES (1, 1, 'Savings', 1000, SYSDATE);

INSERT INTO Accounts (AccountID, CustomerID, AccountType, Balance, LastModified)
VALUES (2, 2, 'Checking', 1500, SYSDATE);

INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (1, 1, SYSDATE, 200, 'Deposit');

INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (2, 2, SYSDATE, 300, 'Withdrawal');

INSERT INTO Loans (LoanID, CustomerID, LoanAmount, InterestRate, StartDate, EndDate)
VALUES (1, 1, 5000, 5, SYSDATE, ADD_MONTHS(SYSDATE, 60));

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (1, 'Alice Johnson', 'Manager', 70000, 'HR', TO_DATE('2015-06-15', 'YYYY-MM-DD'));

INSERT INTO Employees (EmployeeID, Name, Position, Salary, Department, HireDate)
VALUES (2, 'Bob Brown', 'Developer', 60000, 'IT', TO_DATE('2017-03-20', 'YYYY-MM-DD'));

-- ========================================
-- FUNCTION 1: CalculateAge
-- ========================================
CREATE OR REPLACE FUNCTION CalculateAge(p_dob DATE)
RETURN NUMBER IS
    v_age NUMBER;
BEGIN
    v_age := TRUNC(MONTHS_BETWEEN(SYSDATE, p_dob) / 12);
    RETURN v_age;
END;
/

-- ========================================
-- FUNCTION 2: CalculateMonthlyInstallment
-- ========================================
CREATE OR REPLACE FUNCTION CalculateMonthlyInstallment(
    p_loan_amount NUMBER,
    p_interest_rate NUMBER,
    p_years NUMBER
) RETURN NUMBER IS
    v_monthly_rate NUMBER;
    v_months NUMBER;
    v_installment NUMBER;
BEGIN
    v_monthly_rate := p_interest_rate / 12 / 100;
    v_months := p_years * 12;

    IF v_monthly_rate = 0 THEN
        v_installment := p_loan_amount / v_months;
    ELSE
        v_installment := p_loan_amount * v_monthly_rate /
                         (1 - POWER(1 + v_monthly_rate, -v_months));
    END IF;

    RETURN ROUND(v_installment, 2);
END;
/

-- ========================================
-- FUNCTION 3: HasSufficientBalance
-- ========================================
CREATE OR REPLACE FUNCTION HasSufficientBalance(
    p_account_id NUMBER,
    p_amount NUMBER
) RETURN BOOLEAN IS
    v_balance NUMBER;
BEGIN
    SELECT Balance INTO v_balance
    FROM Accounts
    WHERE AccountID = p_account_id;

    RETURN v_balance >= p_amount;
END;
/

-- ========================================
-- FUNCTION USAGE EXAMPLES
-- ========================================

-- 1. CalculateAge usage
SELECT Name, CalculateAge(DOB) AS Age FROM Customers;

-- 2. CalculateMonthlyInstallment usage
SELECT 
    LoanID, 
    CalculateMonthlyInstallment(LoanAmount, InterestRate, 5) AS Monthly_Installment
FROM Loans;

-- 3. HasSufficientBalance usage with anonymous block
DECLARE
    v_result BOOLEAN;
BEGIN
    v_result := HasSufficientBalance(1, 800);
    IF v_result THEN
        DBMS_OUTPUT.PUT_LINE('Sufficient Balance');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Insufficient Balance');
    END IF;
END;
/
