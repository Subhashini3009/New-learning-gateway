-- Enable output display (if using SQL Developer or SQL*Plus)
SET SERVEROUTPUT ON;

-- ================================================
-- SCENARIO 1: GenerateMonthlyStatements
-- Print all transactions for the current month
-- ================================================
DECLARE
    CURSOR txn_cursor IS
        SELECT C.CustomerID, C.Name, T.TransactionDate, T.Amount, T.TransactionType
        FROM Customers C
        JOIN Accounts A ON C.CustomerID = A.CustomerID
        JOIN Transactions T ON A.AccountID = T.AccountID
        WHERE EXTRACT(MONTH FROM T.TransactionDate) = EXTRACT(MONTH FROM SYSDATE)
          AND EXTRACT(YEAR FROM T.TransactionDate) = EXTRACT(YEAR FROM SYSDATE)
        ORDER BY C.CustomerID, T.TransactionDate;

    v_customer_id Customers.CustomerID%TYPE;
    v_name Customers.Name%TYPE;
    v_date Transactions.TransactionDate%TYPE;
    v_amount Transactions.Amount%TYPE;
    v_type Transactions.TransactionType%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Monthly Statement (' || TO_CHAR(SYSDATE, 'Month YYYY') || ') =====');
    DBMS_OUTPUT.PUT_LINE('-------------------------------------------------------');

    OPEN txn_cursor;
    LOOP
        FETCH txn_cursor INTO v_customer_id, v_name, v_date, v_amount, v_type;
        EXIT WHEN txn_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Customer: ' || v_name || 
                             ' | Date: ' || TO_CHAR(v_date, 'DD-MON-YYYY') || 
                             ' | Type: ' || v_type || 
                             ' | Amount: ₹' || v_amount);
    END LOOP;
    CLOSE txn_cursor;
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- ================================================
-- SCENARIO 2: ApplyAnnualFee
-- Deduct a fixed fee from each account
-- ================================================
DECLARE
    CURSOR acc_cursor IS
        SELECT AccountID, Balance FROM Accounts;

    v_acc_id Accounts.AccountID%TYPE;
    v_balance Accounts.Balance%TYPE;
    v_fee CONSTANT NUMBER := 100;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Applying Annual Fee of ₹' || v_fee || ' =====');

    OPEN acc_cursor;
    LOOP
        FETCH acc_cursor INTO v_acc_id, v_balance;
        EXIT WHEN acc_cursor%NOTFOUND;

        UPDATE Accounts
        SET Balance = Balance - v_fee
        WHERE AccountID = v_acc_id;

        DBMS_OUTPUT.PUT_LINE('Fee applied to Account ' || v_acc_id || 
                             '. New Balance: ₹' || (v_balance - v_fee));
    END LOOP;
    CLOSE acc_cursor;
    DBMS_OUTPUT.PUT_LINE('');
END;
/

-- ================================================
-- SCENARIO 3: UpdateLoanInterestRates
-- Adjust loan interest rates per new policy
-- ================================================
DECLARE
    CURSOR loan_cursor IS
        SELECT LoanID, InterestRate FROM Loans;

    v_loan_id Loans.LoanID%TYPE;
    v_old_rate Loans.InterestRate%TYPE;
    v_new_rate Loans.InterestRate%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('===== Updating Loan Interest Rates =====');

    OPEN loan_cursor;
    LOOP
        FETCH loan_cursor INTO v_loan_id, v_old_rate;
        EXIT WHEN loan_cursor%NOTFOUND;

        IF v_old_rate < 5 THEN
            v_new_rate := 5;
        ELSIF v_old_rate < 7 THEN
            v_new_rate := v_old_rate + 1;
        ELSE
            v_new_rate := v_old_rate;
        END IF;

        IF v_old_rate <> v_new_rate THEN
            UPDATE Loans
            SET InterestRate = v_new_rate
            WHERE LoanID = v_loan_id;

            DBMS_OUTPUT.PUT_LINE('Loan ' || v_loan_id || 
                                 ' updated from ' || v_old_rate || '% to ' || v_new_rate || '%');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Loan ' || v_loan_id || 
                                 ' already optimal at ' || v_old_rate || '%');
        END IF;
    END LOOP;
    CLOSE loan_cursor;
END;
/
