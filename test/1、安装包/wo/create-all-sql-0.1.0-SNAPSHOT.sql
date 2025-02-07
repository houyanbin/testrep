CREATE TABLE active_executing_flows (
  exec_id     INT,
  update_time BIGINT,
  PRIMARY KEY (exec_id)
);
CREATE TABLE active_sla (
  exec_id    INT          NOT NULL,
  job_name   VARCHAR(128) NOT NULL,
  check_time BIGINT       NOT NULL,
  rule       TINYINT      NOT NULL,
  enc_type   TINYINT,
  options    LONGBLOB     NOT NULL,
  PRIMARY KEY (exec_id, job_name)
);
CREATE TABLE execution_dependencies(
  trigger_instance_id varchar(64),
  dep_name varchar(128),
  starttime bigint(20) not null,
  endtime bigint(20),
  dep_status tinyint not null,
  cancelleation_cause tinyint not null,

  project_id INT not null,
  project_version INT not null,
  flow_id varchar(128) not null,
  flow_version INT not null,
  flow_exec_id INT not null,
  primary key(trigger_instance_id, dep_name)
);

CREATE INDEX ex_end_time
  ON execution_dependencies (endtime);
CREATE TABLE execution_flows (
  exec_id     INT          NOT NULL AUTO_INCREMENT,
  project_id  INT          NOT NULL,
  version     INT          NOT NULL,
  flow_id     VARCHAR(128) NOT NULL,
  status      TINYINT,
  submit_user VARCHAR(64),
  submit_time BIGINT,
  update_time BIGINT,
  start_time  BIGINT,
  end_time    BIGINT,
  enc_type    TINYINT,
  flow_data   LONGBLOB,
  executor_id INT                   DEFAULT NULL,
  PRIMARY KEY (exec_id)
);

CREATE INDEX ex_flows_start_time
  ON execution_flows (start_time);
CREATE INDEX ex_flows_end_time
  ON execution_flows (end_time);
CREATE INDEX ex_flows_time_range
  ON execution_flows (start_time, end_time);
CREATE INDEX ex_flows_flows
  ON execution_flows (project_id, flow_id);
CREATE INDEX executor_id
  ON execution_flows (executor_id);
CREATE INDEX ex_flows_staus
  ON execution_flows (status);
CREATE TABLE execution_jobs (
  exec_id       INT          NOT NULL,
  project_id    INT          NOT NULL,
  version       INT          NOT NULL,
  flow_id       VARCHAR(128) NOT NULL,
  job_id        VARCHAR(512) NOT NULL,
  attempt       INT,
  start_time    BIGINT,
  end_time      BIGINT,
  status        TINYINT,
  input_params  LONGBLOB,
  output_params LONGBLOB,
  attachments   LONGBLOB,
  PRIMARY KEY (exec_id, job_id, flow_id, attempt)
);

CREATE INDEX ex_job_id
  ON execution_jobs (project_id, job_id);
-- In table execution_logs, name is the combination of flow_id and job_id
--
-- prefix support and lengths of prefixes (where supported) are storage engine dependent.
-- By default, the index key prefix length limit is 767 bytes for innoDB.
-- from: https://dev.mysql.com/doc/refman/5.7/en/create-index.html

CREATE TABLE execution_logs (
  exec_id     INT NOT NULL,
  name        VARCHAR(640),
  attempt     INT,
  enc_type    TINYINT,
  start_byte  INT,
  end_byte    INT,
  log         LONGBLOB,
  upload_time BIGINT,
  PRIMARY KEY (exec_id, name, attempt, start_byte)
);

CREATE INDEX ex_log_attempt
  ON execution_logs (exec_id, name, attempt);
CREATE INDEX ex_log_index
  ON execution_logs (exec_id, name);
CREATE INDEX ex_log_upload_time
  ON execution_logs (upload_time);
CREATE TABLE executor_events (
  executor_id INT      NOT NULL,
  event_type  TINYINT  NOT NULL,
  event_time  DATETIME NOT NULL,
  username    VARCHAR(64),
  message     VARCHAR(512)
);

CREATE INDEX executor_log
  ON executor_events (executor_id, event_time);
CREATE TABLE executors (
  id     INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
  host   VARCHAR(64) NOT NULL,
  port   INT         NOT NULL,
  active BOOLEAN                          DEFAULT FALSE,
  UNIQUE (host, port),
  UNIQUE INDEX executor_id (id)
);

CREATE INDEX executor_connection
  ON executors (host, port);
CREATE TABLE project_events (
  project_id INT     NOT NULL,
  event_type TINYINT NOT NULL,
  event_time BIGINT  NOT NULL,
  username   VARCHAR(64),
  message    VARCHAR(512)
);

CREATE INDEX log
  ON project_events (project_id, event_time);
CREATE TABLE project_files (
  project_id INT NOT NULL,
  version    INT NOT NULL,
  chunk      INT,
  size       INT,
  file       LONGBLOB,
  PRIMARY KEY (project_id, version, chunk)
);

CREATE INDEX file_version
  ON project_files (project_id, version);
CREATE TABLE project_flow_files (
  project_id        INT          NOT NULL,
  project_version   INT          NOT NULL,
  flow_name         VARCHAR(128) NOT NULL,
  flow_version      INT          NOT NULL,
  modified_time     BIGINT       NOT NULL,
  flow_file         LONGBLOB,
  PRIMARY KEY (project_id, project_version, flow_name, flow_version)
);
CREATE TABLE project_flows (
  project_id    INT    NOT NULL,
  version       INT    NOT NULL,
  flow_id       VARCHAR(128),
  modified_time BIGINT NOT NULL,
  encoding_type TINYINT,
  json          BLOB,
  PRIMARY KEY (project_id, version, flow_id)
);

CREATE INDEX flow_index
  ON project_flows (project_id, version);
CREATE TABLE project_permissions (
  project_id    VARCHAR(64) NOT NULL,
  modified_time BIGINT      NOT NULL,
  name          VARCHAR(64) NOT NULL,
  permissions   INT         NOT NULL,
  isGroup       BOOLEAN     NOT NULL,
  PRIMARY KEY (project_id, name)
);

CREATE INDEX permission_index
  ON project_permissions (project_id);
CREATE TABLE project_properties (
  project_id    INT    NOT NULL,
  version       INT    NOT NULL,
  name          VARCHAR(255),
  modified_time BIGINT NOT NULL,
  encoding_type TINYINT,
  property      BLOB,
  PRIMARY KEY (project_id, version, name)
);

CREATE INDEX properties_index
  ON project_properties (project_id, version);
CREATE TABLE project_versions (
  project_id  INT         NOT NULL,
  version     INT         NOT NULL,
  upload_time BIGINT      NOT NULL,
  uploader    VARCHAR(64) NOT NULL,
  file_type   VARCHAR(16),
  file_name   VARCHAR(128),
  md5         BINARY(16),
  num_chunks  INT,
  resource_id VARCHAR(512) DEFAULT NULL,
  PRIMARY KEY (project_id, version)
);

CREATE INDEX version_index
  ON project_versions (project_id);
CREATE TABLE projects (
  id               INT         NOT NULL PRIMARY KEY AUTO_INCREMENT,
  name             VARCHAR(64) NOT NULL,
  active           BOOLEAN,
  modified_time    BIGINT      NOT NULL,
  create_time      BIGINT      NOT NULL,
  version          INT,
  last_modified_by VARCHAR(64) NOT NULL,
  description      VARCHAR(2048),
  enc_type         TINYINT,
  settings_blob    LONGBLOB,
  UNIQUE INDEX project_id (id)
);

CREATE INDEX project_name
  ON projects (name);
CREATE TABLE properties (
  name          VARCHAR(64) NOT NULL,
  type          INT         NOT NULL,
  modified_time BIGINT      NOT NULL,
  value         VARCHAR(256),
  PRIMARY KEY (name, type)
);
-- This file collects all quartz table create statement required for quartz 2.2.1
--
-- We are using Quartz 2.2.1 tables, the original place of which can be found at
-- https://github.com/quartz-scheduler/quartz/blob/quartz-2.2.1/distribution/src/main/assembly/root/docs/dbTables/tables_mysql.sql


DROP TABLE IF EXISTS QRTZ_FIRED_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_PAUSED_TRIGGER_GRPS;
DROP TABLE IF EXISTS QRTZ_SCHEDULER_STATE;
DROP TABLE IF EXISTS QRTZ_LOCKS;
DROP TABLE IF EXISTS QRTZ_SIMPLE_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_SIMPROP_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_CRON_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_BLOB_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_TRIGGERS;
DROP TABLE IF EXISTS QRTZ_JOB_DETAILS;
DROP TABLE IF EXISTS QRTZ_CALENDARS;


CREATE TABLE QRTZ_JOB_DETAILS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    JOB_NAME  VARCHAR(200) NOT NULL,
    JOB_GROUP VARCHAR(200) NOT NULL,
    DESCRIPTION VARCHAR(250) NULL,
    JOB_CLASS_NAME   VARCHAR(250) NOT NULL,
    IS_DURABLE VARCHAR(1) NOT NULL,
    IS_NONCONCURRENT VARCHAR(1) NOT NULL,
    IS_UPDATE_DATA VARCHAR(1) NOT NULL,
    REQUESTS_RECOVERY VARCHAR(1) NOT NULL,
    JOB_DATA BLOB NULL,
    PRIMARY KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    JOB_NAME  VARCHAR(200) NOT NULL,
    JOB_GROUP VARCHAR(200) NOT NULL,
    DESCRIPTION VARCHAR(250) NULL,
    NEXT_FIRE_TIME BIGINT(13) NULL,
    PREV_FIRE_TIME BIGINT(13) NULL,
    PRIORITY INTEGER NULL,
    TRIGGER_STATE VARCHAR(16) NOT NULL,
    TRIGGER_TYPE VARCHAR(8) NOT NULL,
    START_TIME BIGINT(13) NOT NULL,
    END_TIME BIGINT(13) NULL,
    CALENDAR_NAME VARCHAR(200) NULL,
    MISFIRE_INSTR SMALLINT(2) NULL,
    JOB_DATA BLOB NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,JOB_NAME,JOB_GROUP)
        REFERENCES QRTZ_JOB_DETAILS(SCHED_NAME,JOB_NAME,JOB_GROUP)
);

CREATE TABLE QRTZ_SIMPLE_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    REPEAT_COUNT BIGINT(7) NOT NULL,
    REPEAT_INTERVAL BIGINT(12) NOT NULL,
    TIMES_TRIGGERED BIGINT(10) NOT NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_CRON_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    CRON_EXPRESSION VARCHAR(200) NOT NULL,
    TIME_ZONE_ID VARCHAR(80),
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_SIMPROP_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    STR_PROP_1 VARCHAR(512) NULL,
    STR_PROP_2 VARCHAR(512) NULL,
    STR_PROP_3 VARCHAR(512) NULL,
    INT_PROP_1 INT NULL,
    INT_PROP_2 INT NULL,
    LONG_PROP_1 BIGINT NULL,
    LONG_PROP_2 BIGINT NULL,
    DEC_PROP_1 NUMERIC(13,4) NULL,
    DEC_PROP_2 NUMERIC(13,4) NULL,
    BOOL_PROP_1 VARCHAR(1) NULL,
    BOOL_PROP_2 VARCHAR(1) NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
    REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_BLOB_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    BLOB_DATA BLOB NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP),
    FOREIGN KEY (SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
        REFERENCES QRTZ_TRIGGERS(SCHED_NAME,TRIGGER_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_CALENDARS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    CALENDAR_NAME  VARCHAR(200) NOT NULL,
    CALENDAR BLOB NOT NULL,
    PRIMARY KEY (SCHED_NAME,CALENDAR_NAME)
);

CREATE TABLE QRTZ_PAUSED_TRIGGER_GRPS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    TRIGGER_GROUP  VARCHAR(200) NOT NULL,
    PRIMARY KEY (SCHED_NAME,TRIGGER_GROUP)
);

CREATE TABLE QRTZ_FIRED_TRIGGERS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    ENTRY_ID VARCHAR(95) NOT NULL,
    TRIGGER_NAME VARCHAR(200) NOT NULL,
    TRIGGER_GROUP VARCHAR(200) NOT NULL,
    INSTANCE_NAME VARCHAR(200) NOT NULL,
    FIRED_TIME BIGINT(13) NOT NULL,
    SCHED_TIME BIGINT(13) NOT NULL,
    PRIORITY INTEGER NOT NULL,
    STATE VARCHAR(16) NOT NULL,
    JOB_NAME VARCHAR(200) NULL,
    JOB_GROUP VARCHAR(200) NULL,
    IS_NONCONCURRENT VARCHAR(1) NULL,
    REQUESTS_RECOVERY VARCHAR(1) NULL,
    PRIMARY KEY (SCHED_NAME,ENTRY_ID)
);

CREATE TABLE QRTZ_SCHEDULER_STATE
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    INSTANCE_NAME VARCHAR(200) NOT NULL,
    LAST_CHECKIN_TIME BIGINT(13) NOT NULL,
    CHECKIN_INTERVAL BIGINT(13) NOT NULL,
    PRIMARY KEY (SCHED_NAME,INSTANCE_NAME)
);

CREATE TABLE QRTZ_LOCKS
  (
    SCHED_NAME VARCHAR(120) NOT NULL,
    LOCK_NAME  VARCHAR(40) NOT NULL,
    PRIMARY KEY (SCHED_NAME,LOCK_NAME)
);


commit;
CREATE TABLE triggers (
  trigger_id     INT    NOT NULL AUTO_INCREMENT,
  trigger_source VARCHAR(128),
  modify_time    BIGINT NOT NULL,
  enc_type       TINYINT,
  data           LONGBLOB,
  PRIMARY KEY (trigger_id)
);
