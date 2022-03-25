CREATE TABLE users (
  id serial PRIMARY KEY,
  username text UNIQUE NOT NULL
);

CREATE TABLE workouts (
  id serial PRIMARY KEY,
  user_id int NOT NULL REFERENCES users(id),
  exercise_date date NOT NULL,
  exercise_name text NOT NULL,
  reps int CHECK (reps > 0),
  weight numeric(5, 2) CHECK (weight > 0)
);