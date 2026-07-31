-- Data Modeling exercise: PostgreSQL DDL and smoke-test data.
-- Run with: psql -d <database_name> -f data_modeling.sql

-- ============================================================================
-- Part 1A: Medical Center
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS medical_center;
SET search_path TO medical_center;

CREATE TABLE centers (
  center_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL,
  street_address text NOT NULL,
  city text NOT NULL,
  state_code char(2) NOT NULL,
  postal_code text NOT NULL
);

CREATE TABLE doctors (
  doctor_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  license_number text NOT NULL UNIQUE,
  specialty text NOT NULL
);

CREATE TABLE doctor_employments (
  doctor_employment_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  center_id integer NOT NULL REFERENCES centers(center_id),
  doctor_id integer NOT NULL REFERENCES doctors(doctor_id),
  employed_from date NOT NULL,
  employed_until date,
  CHECK (employed_until IS NULL OR employed_until >= employed_from)
);

CREATE TABLE patients (
  patient_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  date_of_birth date NOT NULL,
  phone text,
  email text UNIQUE
);

CREATE TABLE diseases (
  disease_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  icd10_code text NOT NULL UNIQUE,
  name text NOT NULL UNIQUE,
  description text
);

CREATE TABLE visits (
  visit_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  doctor_employment_id integer NOT NULL
    REFERENCES doctor_employments(doctor_employment_id),
  patient_id integer NOT NULL REFERENCES patients(patient_id),
  visited_at timestamptz NOT NULL,
  notes text
);

CREATE TABLE visit_diagnoses (
  visit_id integer NOT NULL REFERENCES visits(visit_id) ON DELETE CASCADE,
  disease_id integer NOT NULL REFERENCES diseases(disease_id),
  diagnosed_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (visit_id, disease_id)
);

INSERT INTO centers (name, street_address, city, state_code, postal_code)
VALUES ('Northside Medical Center', '100 Main St', 'Seattle', 'WA', '98101');
INSERT INTO doctors (first_name, last_name, license_number, specialty)
VALUES ('Avery', 'Chen', 'WA-12345', 'Family Medicine');
INSERT INTO doctor_employments (center_id, doctor_id, employed_from)
VALUES (1, 1, '2024-01-01');
INSERT INTO patients (first_name, last_name, date_of_birth, email)
VALUES ('Jordan', 'Lee', '1992-06-15', 'jordan.lee@example.test');
INSERT INTO diseases (icd10_code, name)
VALUES ('J06.9', 'Acute upper respiratory infection, unspecified'),
       ('R50.9', 'Fever, unspecified');
INSERT INTO visits (doctor_employment_id, patient_id, visited_at, notes)
VALUES (1, 1, '2026-07-30 09:00-07', 'Patient reports cough and fever.');
INSERT INTO visit_diagnoses (visit_id, disease_id)
VALUES (1, 1), (1, 2);

-- ============================================================================
-- Part 1B: Craigslist
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS craigslist;
SET search_path TO craigslist;

CREATE TABLE regions (
  region_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL UNIQUE,
  country_code char(2) NOT NULL,
  timezone_name text NOT NULL
);

CREATE TABLE users (
  user_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  username text NOT NULL UNIQUE,
  email text NOT NULL UNIQUE,
  preferred_region_id integer REFERENCES regions(region_id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE categories (
  category_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL UNIQUE,
  description text
);

CREATE TABLE posts (
  post_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id integer NOT NULL REFERENCES users(user_id),
  region_id integer NOT NULL REFERENCES regions(region_id),
  title text NOT NULL CHECK (length(trim(title)) > 0),
  body text NOT NULL CHECK (length(trim(body)) > 0),
  location_text text NOT NULL,
  posted_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  CHECK (expires_at IS NULL OR expires_at > posted_at)
);

CREATE TABLE post_categories (
  post_id integer NOT NULL REFERENCES posts(post_id) ON DELETE CASCADE,
  category_id integer NOT NULL REFERENCES categories(category_id),
  PRIMARY KEY (post_id, category_id)
);

INSERT INTO regions (name, country_code, timezone_name)
VALUES ('Seattle', 'US', 'America/Los_Angeles'),
       ('San Francisco Bay Area', 'US', 'America/Los_Angeles');
INSERT INTO users (username, email, preferred_region_id)
VALUES ('river', 'river@example.test', 1);
INSERT INTO categories (name, description)
VALUES ('Bicycles', 'Bikes and cycling accessories'),
       ('Sporting goods', 'Equipment for sports and outdoor activities');
INSERT INTO posts (user_id, region_id, title, body, location_text, expires_at)
VALUES (1, 1, 'Road bike for sale', 'Well-maintained 54 cm road bike.',
        'Capitol Hill, Seattle', now() + interval '30 days');
INSERT INTO post_categories (post_id, category_id) VALUES (1, 1), (1, 2);

-- ============================================================================
-- Part 1C: Soccer League
-- ============================================================================
CREATE SCHEMA IF NOT EXISTS soccer;
SET search_path TO soccer;

CREATE TABLE leagues (
  league_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL UNIQUE
);

CREATE TABLE seasons (
  season_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  league_id integer NOT NULL REFERENCES leagues(league_id),
  name text NOT NULL,
  starts_on date NOT NULL,
  ends_on date NOT NULL,
  UNIQUE (league_id, name),
  CHECK (ends_on >= starts_on)
);

CREATE TABLE teams (
  team_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name text NOT NULL UNIQUE,
  home_city text
);

CREATE TABLE team_seasons (
  team_season_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  team_id integer NOT NULL REFERENCES teams(team_id),
  season_id integer NOT NULL REFERENCES seasons(season_id),
  UNIQUE (team_id, season_id)
);

CREATE TABLE players (
  player_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  date_of_birth date,
  UNIQUE (first_name, last_name, date_of_birth)
);

-- Preserves player/team history when a player transfers between teams.
CREATE TABLE player_team_assignments (
  player_team_assignment_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  player_id integer NOT NULL REFERENCES players(player_id),
  team_season_id integer NOT NULL REFERENCES team_seasons(team_season_id),
  starts_on date NOT NULL,
  ends_on date,
  shirt_number smallint,
  CHECK (ends_on IS NULL OR ends_on >= starts_on),
  CHECK (shirt_number IS NULL OR shirt_number BETWEEN 1 AND 99)
);

CREATE TABLE referees (
  referee_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  first_name text NOT NULL,
  last_name text NOT NULL,
  certification_number text NOT NULL UNIQUE
);

CREATE TABLE matches (
  match_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  season_id integer NOT NULL REFERENCES seasons(season_id),
  home_team_season_id integer NOT NULL REFERENCES team_seasons(team_season_id),
  away_team_season_id integer NOT NULL REFERENCES team_seasons(team_season_id),
  kickoff_at timestamptz NOT NULL,
  status text NOT NULL DEFAULT 'scheduled'
    CHECK (status IN ('scheduled', 'completed', 'cancelled')),
  home_score smallint NOT NULL DEFAULT 0 CHECK (home_score >= 0),
  away_score smallint NOT NULL DEFAULT 0 CHECK (away_score >= 0),
  CHECK (home_team_season_id <> away_team_season_id)
);

CREATE TABLE match_referees (
  match_id integer NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
  referee_id integer NOT NULL REFERENCES referees(referee_id),
  referee_role text NOT NULL CHECK (referee_role IN ('center', 'assistant_1', 'assistant_2', 'fourth_official')),
  PRIMARY KEY (match_id, referee_id),
  UNIQUE (match_id, referee_role)
);

CREATE TABLE goals (
  goal_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  match_id integer NOT NULL REFERENCES matches(match_id) ON DELETE CASCADE,
  scorer_player_id integer NOT NULL REFERENCES players(player_id),
  scoring_team_season_id integer NOT NULL REFERENCES team_seasons(team_season_id),
  scored_in_minute smallint NOT NULL CHECK (scored_in_minute BETWEEN 0 AND 130),
  is_own_goal boolean NOT NULL DEFAULT false
);

-- Standings are derived from completed matches; they are not stored separately.
CREATE VIEW standings AS
WITH team_results AS (
  SELECT season_id, home_team_season_id AS team_season_id,
         home_score AS goals_for, away_score AS goals_against,
         CASE WHEN home_score > away_score THEN 3 WHEN home_score = away_score THEN 1 ELSE 0 END AS points,
         CASE WHEN home_score > away_score THEN 1 ELSE 0 END AS wins,
         CASE WHEN home_score = away_score THEN 1 ELSE 0 END AS draws,
         CASE WHEN home_score < away_score THEN 1 ELSE 0 END AS losses
  FROM matches WHERE status = 'completed'
  UNION ALL
  SELECT season_id, away_team_season_id,
         away_score, home_score,
         CASE WHEN away_score > home_score THEN 3 WHEN away_score = home_score THEN 1 ELSE 0 END,
         CASE WHEN away_score > home_score THEN 1 ELSE 0 END,
         CASE WHEN away_score = home_score THEN 1 ELSE 0 END,
         CASE WHEN away_score < home_score THEN 1 ELSE 0 END
  FROM matches WHERE status = 'completed'
)
SELECT tr.season_id, ts.team_season_id, t.name AS team_name,
       COUNT(*) AS matches_played, SUM(tr.wins) AS wins, SUM(tr.draws) AS draws,
       SUM(tr.losses) AS losses, SUM(tr.goals_for) AS goals_for,
       SUM(tr.goals_against) AS goals_against, SUM(tr.goals_for - tr.goals_against) AS goal_difference,
       SUM(tr.points) AS points,
       RANK() OVER (PARTITION BY tr.season_id ORDER BY SUM(tr.points) DESC,
                    SUM(tr.goals_for - tr.goals_against) DESC, SUM(tr.goals_for) DESC) AS rank
FROM team_results tr
JOIN team_seasons ts ON ts.team_season_id = tr.team_season_id
JOIN teams t ON t.team_id = ts.team_id
GROUP BY tr.season_id, ts.team_season_id, t.name;

INSERT INTO leagues (name) VALUES ('Puget Sound League');
INSERT INTO seasons (league_id, name, starts_on, ends_on)
VALUES (1, '2026 Summer', '2026-05-01', '2026-08-31');
INSERT INTO teams (name, home_city) VALUES ('Harbor FC', 'Seattle'), ('Rain City FC', 'Seattle');
INSERT INTO team_seasons (team_id, season_id) VALUES (1, 1), (2, 1);
INSERT INTO players (first_name, last_name, date_of_birth)
VALUES ('Sam', 'Rivera', '1998-03-22'), ('Casey', 'Morgan', '1995-11-09');
INSERT INTO player_team_assignments (player_id, team_season_id, starts_on, shirt_number)
VALUES (1, 1, '2026-05-01', 9), (2, 2, '2026-05-01', 10);
INSERT INTO referees (first_name, last_name, certification_number)
VALUES ('Taylor', 'Nguyen', 'REF-9001');
INSERT INTO matches (season_id, home_team_season_id, away_team_season_id, kickoff_at, status, home_score, away_score)
VALUES (1, 1, 2, '2026-06-01 19:00-07', 'completed', 1, 1);
INSERT INTO match_referees (match_id, referee_id, referee_role) VALUES (1, 1, 'center');
INSERT INTO goals (match_id, scorer_player_id, scoring_team_season_id, scored_in_minute)
VALUES (1, 1, 1, 12), (1, 2, 2, 75);

-- Helpful checks after loading the script:
-- SELECT * FROM medical_center.visit_diagnoses;
-- SELECT * FROM craigslist.posts JOIN craigslist.post_categories USING (post_id);
-- SELECT * FROM soccer.standings;
