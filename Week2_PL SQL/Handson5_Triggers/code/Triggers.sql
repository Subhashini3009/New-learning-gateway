-- =====================================================
-- AUDIT TABLE CREATION (Used in LogTransaction trigger)
-- =====================================================
CREATE TABLE AuditLog (
    LogID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    TransactionID NUMBER,
    AccountID NUMBER,
    Amount NUMBER,
    TransactionType VARCHAR2(10),
    LogDate DATE DEFAULT SYSDATE
);

-- =====================================================
-- TRIGGER 1: UpdateCustomerLastModified
-- Automatically updates LastModified when a Customer is updated
-- =====================================================
CREATE OR REPLACE TRIGGER UpdateCustomerLastModified
BEFORE UPDATE ON Customers
FOR EACH ROW
BEGIN
    :NEW.LastModified := SYSDATE;
END;
/

-- =====================================================
-- TRIGGER 2: LogTransaction
-- Inserts a log into AuditLog whenever a Transaction is inserted
-- =====================================================
CREATE OR REPLACE TRIGGER LogTransaction
AFTER INSERT ON Transactions
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (TransactionID, AccountID, Amount, TransactionType)
    VALUES (:NEW.TransactionID, :NEW.AccountID, :NEW.Amount, :NEW.TransactionType);
END;
/

-- =====================================================
-- TRIGGER 3: CheckTransactionRules
-- Validates withdrawal and deposit conditions before insertion
-- =====================================================
CREATE OR REPLACE TRIGGER CheckTransactionRules
BEFORE INSERT ON Transactions
FOR EACH ROW
DECLARE
    v_balance NUMBER;
BEGIN
    -- Get current balance of the account
    SELECT Balance INTO v_balance
    FROM Accounts
    WHERE AccountID = :NEW.AccountID;

    IF :NEW.TransactionType = 'Withdrawal' THEN
        IF :NEW.Amount > v_balance THEN
            RAISE_APPLICATION_ERROR(-20001, 'Withdrawal exceeds account balance.');
        END IF;
    ELSIF :NEW.TransactionType = 'Deposit' THEN
        IF :NEW.Amount <= 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Deposit amount must be positive.');
        END IF;
    ELSE
        RAISE_APPLICATION_ERROR(-20003, 'Invalid transaction type.');
    END IF;
END;
/

-- =====================================================
-- SAMPLE TEST CASES TO VERIFY TRIGGERS
-- =====================================================

-- ✅ Update customer to trigger UpdateCustomerLastModified
UPDATE Customers
SET Name = 'John D.'
WHERE CustomerID = 1;

-- ✅ Insert valid deposit (Triggers LogTransaction and passes CheckTransactionRules)
INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
VALUES (3, 1, SYSDATE, 200, 'Deposit');

-- ❌ Insert invalid withdrawal (Fails CheckTransactionRules)
-- This will throw error if amount > balance
-- INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
-- VALUES (4, 1, SYSDATE, 999999, 'Withdrawal');

-- ❌ Insert invalid deposit (Negative amount - should fail)
-- INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
-- VALUES (5, 1, SYSDATE, -50, 'Deposit');

-- ✅ View AuditLog entries
SELECT * FROM AuditLog;

-- ✅ Check LastModified update
SELECT Name, LastModified FROM Customers;
