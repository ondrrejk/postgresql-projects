/*
First, I'll create a database called bookshelf:
- Note that I am using PostgreSQL.
- We are assuming, that the user is already logged in.
*/

CREATE DATABASE bookshelf;

-- next we connect to that database.
\c bookshelf;

/* I'll be making the tables:
1. authors
2. books
3. members
4. loans
each with their specific columns.
*/

CREATE TABLE authors (
    author_id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    birth_year INT
);

CREATE TABLE books (
    book_id SERIAL NOT NULL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    published_year INT,
    author_id INT REFERENCES authors(author_id)
);

CREATE TABLE members (
    member_id SERIAL NOT NULL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    joined_date DATE DEFAULT CURRENT_DATE
);

CREATE TABLE loans (
    loan_id SERIAL NOT NULL PRIMARY KEY,
    book_id INT REFERENCES books(book_id),
    member_id INT REFERENCES members(member_id),
    loan_date DATE DEFAULT CURRENT_DATE,
    return_date DATE
);

/*
Next I'll be inserting this sample data:
- 5 authors
- 10 books
- 5 members
- a few loan records.
*/

INSERT INTO authors (name, birth_year) VALUES ('William Shakespeare', 1564);
INSERT INTO authors (name, birth_year) VALUES ('Agatha Christie', 1890);
INSERT INTO authors (name, birth_year) VALUES ('Barbara Cartland', NULL);
INSERT INTO authors (name, birth_year) VALUES ('Danielle Steel', NULL);
INSERT INTO authors (name, birth_year) VALUES ('Harold Robbins', 1916);

INSERT INTO books (title, published_year, author_id) VALUES ('A Hazard of Hearts', NULL, 3);
INSERT INTO books (title, published_year, author_id) VALUES ('The Promise', 1978, 4);
INSERT INTO books (title, published_year, author_id) VALUES ('Hamlet', 1603, 1);
INSERT INTO books (title, published_year, author_id) VALUES ('Macbeth', NULL, 1);
INSERT INTO books (title, published_year, author_id) VALUES ('The Carpetbaggers', 1961, 5);
INSERT INTO books (title, published_year, author_id) VALUES ('The Wicked Marquis', 1922, 3);
INSERT INTO books (title, published_year, author_id) VALUES ('Murder on the Orient Express', NULL, 2);
INSERT INTO books (title, published_year, author_id) VALUES ('The Adventurers', NULL, 5);
INSERT INTO books (title, published_year, author_id) VALUES ('And Then There Were None', 1939, 2);
INSERT INTO books (title, published_year, author_id) VALUES ('The Ring', NULL, 4);

INSERT INTO members (name, email, joined_date) VALUES ('Alice Johnson', 'alice@example.com', '2023-01-10');
INSERT INTO members (name, email, joined_date) VALUES ('Brian Smith', 'brian@example.com', '2023-02-14');
INSERT INTO members (name, email, joined_date) VALUES ('Carla Mendes', 'carla@example.com', '2023-03-01');
INSERT INTO members (name, email, joined_date) VALUES ('David Lee', 'david@example.com', NULL);
INSERT INTO members (name, email, joined_date) VALUES ('Emily Clark', 'emily@example.com', '2023-04-05');

INSERT INTO loans (book_id, member_id, loan_date, return_date)
VALUES (1, 2, '2023-04-10', '2023-04-20');

INSERT INTO loans (book_id, member_id, loan_date, return_date)
VALUES (3, 1, '2023-04-15', NULL);  -- not returned yet

INSERT INTO loans (book_id, member_id, loan_date, return_date)
VALUES (7, 5, '2023-04-18', '2023-04-25');


-- list all books
SELECT * FROM books;

-- list all members
SELECT * FROM members;

-- find all books by a specific author (ex. Agatha Christie)
SELECT books.book_id, books.title, books.published_year, authors.name AS author
FROM books
JOIN authors ON books.author_id=authors.author_id
WHERE authors.name='Agatha Christie';

-- show all currently borrowed books (where return_date is null)
SELECT books.title, books.published_year, loans.loan_date
FROM books
JOIN loans ON books.book_id=loans.book_id
WHERE loans.return_date IS NULL;

-- show overdue books (where loan_date is older than 30 days from now)
SELECT books.title, books.published_year, loans.loan_date
FROM books
JOIN loans ON books.book_id=loans.book_id
WHERE loans.return_date IS NULL AND loans.loan_date < CURRENT_DATE - INTERVAL '30 days';

-- count how many books each author has written
SELECT authors.name, COUNT(*) AS books
FROM authors
JOIN books ON authors.author_id=books.author_id
GROUP BY authors.name;

-- prevent a book from being loaned multiple times at the same time
CREATE UNIQUE INDEX unique_active_loan_per_book
ON loans.book_id
WHERE return_date IS NULL;

-- create a table for loan history
CREATE TABLE loan_history (
    history_id SERIAL PRIMARY KEY,
    loan_id INT REFERENCES loans.loan_id,
    returned_on DATE NOT NULL
);

-- create a trigger function - track returns into loan history table
CREATE OR REPLACE FUNCTION track_loan_return()
RETURNS TRIGGER AS $$
BEGIN
    -- detect transition from NULL -> NOT NULL
    IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
        INSERT INTO loan_history (loan_id, returned_on)
        VALUES (OLD.loan_id, NEW.return_date);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- return trigger, that is executed on each row every time the loans table is updated
CREATE TRIGGER loan_return_trigger
AFTER UPDATE ON loans
FOR EACH ROW
EXECUTE FUNCTION track_loan_return();

