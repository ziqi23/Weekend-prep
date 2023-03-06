PRAGMA foreign_keys = ON;

CREATE TABLE users(
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

CREATE TABLE questions(
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    associated_author_id INTEGER NOT NULL,
    FOREIGN KEY (associated_author_id) REFERENCES users(id)
);

CREATE TABLE question_follows(
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies(
    id INTEGER PRIMARY KEY,
    body TEXT NOT NULL,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    parent_reply_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (parent_reply_id) REFERENCES replies(id)
);

CREATE TABLE question_likes(
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);



INSERT INTO
    users (fname, lname)
VALUES
    ('Joe', 'Smith'),
    ('Chris', 'Banas'),
    ('Ziqi', 'Zou');

INSERT INTO
    questions (title, body, associated_author_id)
VALUES
    ('Test Title', 'Why isn''t the earth flat!?', 1),
    ('Tired', 'Why I''m so tired', 2),
    ('Early', 'Why I got up early', 3);

INSERT INTO
    replies (body, user_id, question_id, parent_reply_id)
VALUES
    ('Because people believe in crazy things', 2, 1, NULL),
    ('You didn''t sleep', 1, 2, NULL),
    ('Sleep more', 3, 2, 2);

INSERT INTO
    question_follows (user_id, question_id)
VALUES
    (1, 3),
    (2, 1),
    (3, 1);

INSERT INTO
    question_likes (user_id, question_id)
VALUES
    (1, 3),
    (2, 1),
    (3, 1);
