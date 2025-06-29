-- Enable output
SET SERVEROUTPUT ON;

-- 1. Create sequence for TransactionID if not already created
BEGIN
  EXECUTE IMMEDIATE 'CREATE SEQUENCE Transactions_seq START WITH 1001 INCREMENT BY 1';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -955 THEN -- ORA-00955: name already used by existing object
      RAISE;
    END IF;
END;
/

-- 2. Procedure to transfer funds safely
CREATE OR REPLACE PROCEDURE SafeTransferFunds (
  p_FromAccountID IN NUMBER,
  p_ToAccountID   IN NUMBER,
  p_Amount        IN NUMBER
) AS
  v_FromBalance NUMBER;
BEGIN
  -- Lock the sender account row
  SELECT Balance INTO v_FromBalance
  FROM Accounts
  WHERE AccountID = p_FromAccountID
  FOR UPDATE;

  -- Check for sufficient balance
  IF v_FromBalance < p_Amount THEN
    RAISE_APPLICATION_ERROR(-20001, 'Insufficient funds in source account.');
  END IF;

  -- Deduct amount from sender
  UPDATE Accounts
  SET Balance = Balance - p_Amount,
      LastModified = SYSDATE
  WHERE AccountID = p_FromAccountID;

  -- Add amount to receiver
  UPDATE Accounts
  SET Balance = Balance + p_Amount,
      LastModified = SYSDATE
  WHERE AccountID = p_ToAccountID;

  -- Record transactions
  INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
  VALUES (Transactions_seq.NEXTVAL, p_FromAccountID, SYSDATE, p_Amount, 'Debit');

  INSERT INTO Transactions (TransactionID, AccountID, TransactionDate, Amount, TransactionType)
  VALUES (Transactions_seq.NEXTVAL, p_ToAccountID, SYSDATE, p_Amount, 'Credit');

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Funds transferred successfully.');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Transfer failed: ' || SQLERRM);
END;
/

-- 3. Procedure to update salary safely
CREATE OR REPLACE PROCEDURE UpdateSalary (
  p_EmployeeID IN NUMBER,
  p_Percent    IN NUMBER
) AS
BEGIN
  UPDATE Employees
  SET Salary = Salary + (Salary * p_Percent / 100)
  WHERE EmployeeID = p_EmployeeID;

  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Employee not found.');
  END IF;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Salary updated successfully.');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error updating salary: ' || SQLERRM);
END;
/

-- 4. Procedure to add new customer with duplicate ID handling
CREATE OR REPLACE PROCEDURE AddNewCustomer (
  p_CustomerID IN NUMBER,
  p_Name       IN VARCHAR2,
  p_DOB        IN DATE,
  p_Balance    IN NUMBER
) AS
BEGIN
  INSERT INTO Customers (CustomerID, Name, DOB, Balance, LastModified)
  VALUES (p_CustomerID, p_Name, p_DOB, p_Balance, SYSDATE);

  COMMIT;
  DBMS_OUTPUT.PUT_LINE('Customer added successfully.');
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    DBMS_OUTPUT.PUT_LINE('Customer with ID ' || p_CustomerID || ' already exists.');
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error adding new customer: ' || SQLERRM);
END;
/
