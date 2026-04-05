-- ============================================================
--  Acadly — MySQL schema (users, assignments, attendance, progress)
--  Run: node Backend/setup-db.js
--
--  Video library (files + metadata + quizzes): MongoDB / GridFS.
--  user_video_progress.video_id = MongoDB ObjectId string (24 hex).
-- ============================================================

CREATE DATABASE IF NOT EXISTS acadly_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE acadly_db;

-- ------------------------------------------------------------
-- USERS
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
  id           INT          AUTO_INCREMENT PRIMARY KEY,
  email        VARCHAR(255) UNIQUE NOT NULL,
  password     VARCHAR(255) NOT NULL,
  name         VARCHAR(100),
  role         ENUM('student','teacher','admin') NOT NULL DEFAULT 'student',
  avatar_url   VARCHAR(500),
  is_active    TINYINT(1)   NOT NULL DEFAULT 1,
  created_at   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login   TIMESTAMP    NULL
);

-- ------------------------------------------------------------
-- USER PROFILES
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_profiles (
  id           INT  AUTO_INCREMENT PRIMARY KEY,
  user_id      INT  NOT NULL UNIQUE,
  bio          TEXT,
  xp_total     INT  NOT NULL DEFAULT 0,
  streak_days  INT  NOT NULL DEFAULT 0,
  level        INT  NOT NULL DEFAULT 1,
  gpa          DECIMAL(3,2) DEFAULT 0.00,
  department   VARCHAR(100),
  badges_earned JSON,
  last_active  DATE NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- AGGREGATE LEARNING STATS (not per-video; complements Mongo catalog)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_progress (
  user_id                              INT NOT NULL PRIMARY KEY,
  total_videos_watched                 INT NOT NULL DEFAULT 0,
  total_watch_time_minutes             INT NOT NULL DEFAULT 0,
  average_video_completion_percentage  DECIMAL(5,2),
  quiz_pass_rate                       DECIMAL(5,2),
  average_quiz_score                   DECIMAL(5,2),
  streak_current                       INT NOT NULL DEFAULT 0,
  streak_longest                       INT NOT NULL DEFAULT 0,
  certificates_earned                  INT NOT NULL DEFAULT 0,
  last_updated                         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- PER-USER VIDEO COMPLETION (video_id = Mongo ObjectId string)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_video_progress (
  id            INT           AUTO_INCREMENT PRIMARY KEY,
  user_id       INT           NOT NULL,
  video_id      VARCHAR(32)   NOT NULL,
  watch_seconds FLOAT         NOT NULL DEFAULT 0,
  completed     TINYINT(1)    NOT NULL DEFAULT 0,
  xp_awarded    INT           NOT NULL DEFAULT 0,
  quiz_score    INT           NOT NULL DEFAULT 0,
  last_watched  TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_user_video (user_id, video_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- ATTENDANCE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS attendance (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  user_id           INT NOT NULL,
  date              DATE NOT NULL,
  status            ENUM('present','absent','late','excused') NOT NULL DEFAULT 'present',
  check_in_time     TIME NULL,
  check_out_time    TIME NULL,
  duration_minutes  INT NULL,
  notes             TEXT NULL,
  UNIQUE KEY uq_user_date (user_id, date),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- ASSIGNMENTS (no link to MySQL videos table)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS assignments (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  title       VARCHAR(255) NOT NULL,
  description TEXT,
  topic_id    INT NULL,
  due_date    DATETIME NOT NULL,
  max_score   DECIMAL(5,2) NOT NULL DEFAULT 100,
  created_by  INT NOT NULL,
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS assignment_submissions (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  assignment_id   INT NOT NULL,
  user_id         INT NOT NULL,
  submission_url  VARCHAR(1000),
  submission_text TEXT,
  submitted_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  score           DECIMAL(5,2),
  feedback        TEXT,
  graded_by       INT NULL,
  graded_at       TIMESTAMP NULL,
  status          ENUM('submitted','graded','pending') NOT NULL DEFAULT 'pending',
  UNIQUE KEY uq_assignment_user (assignment_id, user_id),
  FOREIGN KEY (assignment_id) REFERENCES assignments(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (graded_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- SEED: default admin
-- ------------------------------------------------------------
INSERT INTO users (email, password, name, role, is_active)
VALUES ('admin@acadly.com', 'CHANGE_ME_HASHED_PASSWORD', 'Acadly Admin', 'admin', 1)
ON DUPLICATE KEY UPDATE role = 'admin';

INSERT INTO user_profiles (user_id, xp_total, streak_days)
SELECT id, 0, 0 FROM users WHERE email = 'admin@acadly.com'
ON DUPLICATE KEY UPDATE user_id = user_id;

INSERT INTO user_progress (user_id, total_videos_watched, total_watch_time_minutes)
SELECT id, 0, 0 FROM users WHERE email = 'admin@acadly.com'
ON DUPLICATE KEY UPDATE user_id = user_id;
