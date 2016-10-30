select * from tuts_rest.RegisteringInfo WHERE userId = 999 order by tuts_rest.RegisteringInfo.id DESC limit 10

call start(1)
call goToNext(1,1)
call getNextNumber(1)
call getServingNumber(1)

DROP PROCEDURE IF EXISTS `getSeats`
CREATE DEFINER=`root`@`localhost` PROCEDURE `getSeats` (IN `doctorID` INT)
BEGIN
    SELECT tuts_rest.SeatAvailable.seatID, tuts_rest.SeatAvailable.status, tuts_rest.SeatAvailable.day
    FROM tuts_rest.SeatAvailable
    WHERE tuts_rest.SeatAvailable.doctorID = doctorID AND tuts_rest.SeatAvailable.seatID < tuts_rest.getSeatSeperator();
END

DROP PROCEDURE IF EXISTS `bookASeat`
CREATE DEFINER=`root`@`localhost` PROCEDURE `bookASeat` (IN `userID` VARCHAR(20), `doctorID` INT, `seatID` SMALLINT)
ThisSP:BEGIN
  	DECLARE registerNumber BIGINT default 1;
    DECLARE dayOff INT default 1;
    DECLARE seatAvailableID BIGINT DEFAULT 0;

    -- RETURN
    -- -2: Day OFF
    -- -1: User already in the waiting list
    -- -3: Out of range
    -- 0: Seat is not available
    -- 1: Seat is available and it's booked

    -- IF CURRUNT_DATE is day off
    SELECT COUNT(doctorID) INTO dayOff
    FROM NonCheckingDay
    WHERE NonCheckingDay.doctorID = doctorID AND NonCheckingDay.day = CURRENT_DATE;

    IF dayOff > 0 THEN
        SELECT tuts_rest.RET_DAY_OFF();
        LEAVE ThisSP;
    END IF;

    -- If user is in the waiting list
    SELECT COUNT(RegisteringInfo.id) INTO registerNumber FROM RegisteringInfo
    WHERE RegisteringInfo.userId = userId AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE AND RegisteringInfo.doctorID = doctorID
          AND RegisteringInfo.registerNumber < getSeatSeperator()
          AND tuts_rest.RegisteringInfo.checkResult IS NULL;

    IF registerNumber > 0 THEN
        SELECT tuts_rest.RET_ALREADY_REGISTER();
        LEAVE ThisSP;
    END IF;

    CASE tuts_rest.getSeatStatus(doctorID,seatID)
      WHEN tuts_rest.CONST_AVAILABLE() THEN
        BEGIN
          START TRANSACTION;
            UPDATE SeatAvailable
            SET SeatAvailable.status = tuts_rest.CONST_BOOKED(), SeatAvailable.day = CURRENT_DATE
            WHERE SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;

            INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId, doctorID, registerNumber, checkResult)
                    VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID, doctorID, seatID, NULL);
            SELECT tuts_rest.RET_BOOK_OK();
          COMMIT;
          LEAVE ThisSP;
        END;
      WHEN tuts_rest.RET_SEAT_OUT_OF_RANGE() THEN
        BEGIN
          SELECT tuts_rest.RET_SEAT_OUT_OF_RANGE();
          LEAVE ThisSP;
        END;
      ELSE
        BEGIN
          SELECT tuts_rest.RET_SEAT_NOT_AVAILABLE();
          LEAVE ThisSP;
        END;
    END CASE;
END


call bookASeat('abcd',1,13)
call unBookASeat('abcd',1,13)

DROP PROCEDURE IF EXISTS `unBookASeat`
CREATE DEFINER=`root`@`localhost` PROCEDURE `unBookASeat` (IN `userID` VARCHAR(20), `doctorID` INT, `seatID` SMALLINT)
BEGIN
    DECLARE rowCount SMALLINT default -1;

    START TRANSACTION;
      UPDATE SeatAvailable
      SET SeatAvailable.status = tuts_rest.CONST_AVAILABLE()
      WHERE SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;

      DELETE FROM tuts_rest.RegisteringInfo
      WHERE tuts_rest.RegisteringInfo.registerNumber = seatID AND tuts_rest.RegisteringInfo.doctorID = doctorID
      AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE AND tuts_rest.RegisteringInfo.userId = userID;

      SELECT ROW_COUNT() into rowCount;
    COMMIT;
    select rowCount;
END

DROP PROCEDURE IF EXISTS `requestAPresenseNumber`
CREATE DEFINER=`root`@`localhost` PROCEDURE `requestAPresenseNumber` (IN `userID` VARCHAR(20), IN `doctorID` INT)
BEGIN
    DECLARE ID BIGINT;
    DECLARE seatID SMALLINT;

    SELECT SeatAvailable.id, SeatAvailable.seatID INTO ID, seatID FROM tuts_rest.SeatAvailable
    WHERE SeatAvailable.seatID  > getSeatSeperator() AND SeatAvailable.doctorID = doctorID
          AND (SeatAvailable.day < CURRENT_DATE OR (SeatAvailable.day = CURRENT_DATE AND tuts_rest.SeatAvailable.status <>1))
    ORDER BY SeatAvailable.seatID ASC
    LIMIT 1;

    IF ID IS NOT NULL THEN
      START TRANSACTION;
          UPDATE tuts_rest.SeatAvailable SET SeatAvailable.status = 1, tuts_rest.SeatAvailable.day = CURRENT_DATE
          WHERE tuts_rest.SeatAvailable.id = ID;
          INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId, doctorID, registerNumber, checkin)
                  VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID, doctorID, seatID, TRUE);
      COMMIT;
    ELSE
      BEGIN
          SET seatID = -1;
      END;
    END IF;
    SELECT seatID;
END

DROP PROCEDURE IF EXISTS `checkIn`
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkIn` (IN `userID` INT, `doctorID` INT)  BEGIN
    UPDATE tuts_rest.RegisteringInfo
    SET tuts_rest.RegisteringInfo.checkin = TRUE
    WHERE tuts_rest.RegisteringInfo.userId = userID AND tuts_rest.RegisteringInfo.doctorID = doctorID
      AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE;
END

DROP PROCEDURE IF EXISTS `start`
CREATE DEFINER=`root`@`localhost` PROCEDURE `start` (IN `doctorID` INT)  BEGIN
    UPDATE tuts_rest.DoctorInfo
    SET tuts_rest.DoctorInfo.planServing = 0, tuts_rest.DoctorInfo.actualServing = 0
    WHERE tuts_rest.DoctorInfo.doctorID = doctorID;
    CALL goToNext(doctorID,1);
END

DROP PROCEDURE IF EXISTS `goToNext`
CREATE DEFINER=`root`@`localhost` PROCEDURE `goToNext` (IN `doctorID` BIGINT, `nextOrSkip` TINYINT)  BEGIN
    DECLARE planServing SMALLINT;
    DECLARE actualServing SMALLINT;
    DECLARE alreadyCheckedIn TINYINT DEFAULT 0;
    DECLARE registerNumber SMALLINT DEFAULT 0;
    DECLARE countResult SMALLINT DEFAULT 0;

    SELECT tuts_rest.DoctorInfo.planServing, tuts_rest.DoctorInfo.actualServing into planServing, actualServing
    FROM DoctorInfo
    where doctorID = doctorID;

    start transaction;
      -- update checkResult in the RegisteringInfo
      UPDATE tuts_rest.RegisteringInfo
      SET tuts_rest.RegisteringInfo.checkResult = nextOrSkip
      WHERE tuts_rest.RegisteringInfo.doctorID = doctorID AND tuts_rest.RegisteringInfo.registerNumber = actualServing
        AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE;

      -- Increase planServing in the DoctorInfo
      SET planServing = planServing + 1;

      UPDATE tuts_rest.DoctorInfo
      SET tuts_rest.DoctorInfo.planServing = planServing
      WHERE tuts_rest.DoctorInfo.doctorID = doctorID;

      -- Identify the next actual number

      SELECT COUNT(tuts_rest.RegisteringInfo.id) into alreadyCheckedIn
      FROM tuts_rest.RegisteringInfo
      WHERE tuts_rest.RegisteringInfo.doctorID = doctorID AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE
          AND tuts_rest.RegisteringInfo.checkResult IS NULL AND tuts_rest.RegisteringInfo.checkin = TRUE
          AND tuts_rest.RegisteringInfo.registerNumber = planServing;

      -- 1. if the registering number is alreay check in
      IF alreadyCheckedIn > 0 THEN
        UPDATE tuts_rest.DoctorInfo
        SET tuts_rest.DoctorInfo.actualServing = planServing
        WHERE tuts_rest.DoctorInfo.doctorID = doctorID;
      -- regisetering number is not yet check in OR there is no one register the planServing seat
      ELSE
        BEGIN
          SELECT COUNT (tuts_rest.RegisteringInfo.registerNumber), tuts_rest.RegisteringInfo.registerNumber into countResult, registerNumber
          FROM tuts_rest.RegisteringInfo
          WHERE tuts_rest.RegisteringInfo.registerNumber > tuts_rest.getSeatSeperator() AND tuts_rest.RegisteringInfo.doctorID = doctorID
            AND tuts_rest.RegisteringInfo.checkin = TRUE AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE
            AND tuts_rest.RegisteringInfo.checkResult IS NULL
          GROUP BY tuts_rest.RegisteringInfo.registerNumber
          ORDER BY tuts_rest.RegisteringInfo.registerNumber ASC
          LIMIT 1;
          -- 2. if there is one presenseNumber which is already check in today for this doctor
          IF countResult > 0 THEN
            UPDATE tuts_rest.DoctorInfo
            SET tuts_rest.DoctorInfo.actualServing = registerNumber
            WHERE tuts_rest.DoctorInfo.doctorID = doctorID;
          ELSE
            BEGIN
              SELECT COUNT (tuts_rest.RegisteringInfo.registerNumber), tuts_rest.RegisteringInfo.registerNumber into countResult, registerNumber
              FROM tuts_rest.RegisteringInfo
              WHERE tuts_rest.RegisteringInfo.registerNumber < tuts_rest.getSeatSeperator() AND tuts_rest.RegisteringInfo.doctorID = doctorID
                AND tuts_rest.RegisteringInfo.checkin = TRUE AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE
                AND tuts_rest.RegisteringInfo.checkResult IS NULL
              GROUP BY tuts_rest.RegisteringInfo.registerNumber
              ORDER BY tuts_rest.RegisteringInfo.registerNumber ASC
              LIMIT 1;
              -- 3. if there is NO presenseNumber is being checked in --> PRIO go to the next seatID in case (s)he already checked in
              IF countResult > 0 THEN
                UPDATE tuts_rest.DoctorInfo
                SET tuts_rest.DoctorInfo.actualServing = registerNumber
                WHERE tuts_rest.DoctorInfo.doctorID = doctorID;
              ELSE
                BEGIN
                  UPDATE tuts_rest.DoctorInfo
                  SET tuts_rest.DoctorInfo.actualServing = -1
                  WHERE tuts_rest.DoctorInfo.doctorID = doctorID;
                END;
              END IF;
            END;
          END IF;
        END;
      END IF;
    commit;

    SELECT tuts_rest.DoctorInfo.actualServing
    FROM tuts_rest.DoctorInfo
    where tuts_rest.DoctorInfo.doctorID = doctorID;
END

DROP PROCEDURE IF EXISTS `getNextNumber`
CREATE DEFINER=`root`@`localhost` PROCEDURE `getNextNumber` (IN `doctorID` BIGINT)
ThisSP:BEGIN
    DECLARE planServing SMALLINT;
    DECLARE actualServing SMALLINT;
    DECLARE alreadyCheckedIn TINYINT DEFAULT 0;
    DECLARE registerNumber SMALLINT DEFAULT 0;
    DECLARE countResult SMALLINT DEFAULT 0;
    DECLARE nextNumber SMALLINT DEFAULT 0;

    SELECT tuts_rest.DoctorInfo.planServing, tuts_rest.DoctorInfo.actualServing into planServing, actualServing
    FROM DoctorInfo
    where doctorID = doctorID;

    -- Increase planServing in the DoctorInfo
    SET planServing = planServing + 1;

    -- Identify the next actual number

    SELECT COUNT(tuts_rest.RegisteringInfo.id) into alreadyCheckedIn
    FROM tuts_rest.RegisteringInfo
    WHERE tuts_rest.RegisteringInfo.doctorID = doctorID AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE
        AND tuts_rest.RegisteringInfo.checkResult IS NULL AND tuts_rest.RegisteringInfo.checkin = TRUE
        AND tuts_rest.RegisteringInfo.registerNumber = planServing;

    -- 1. if the registering number is alreay check in
    IF alreadyCheckedIn > 0 THEN
      set nextNumber = planServing;
      select nextNumber;
      LEAVE ThisSP;
    -- regisetering number is not yet check in OR there is no one register the planServing seat
    ELSE
      BEGIN
        SELECT COUNT (tuts_rest.RegisteringInfo.registerNumber), tuts_rest.RegisteringInfo.registerNumber into countResult, registerNumber
        FROM tuts_rest.RegisteringInfo
        WHERE tuts_rest.RegisteringInfo.registerNumber > tuts_rest.getSeatSeperator() AND tuts_rest.RegisteringInfo.doctorID = doctorID
          AND tuts_rest.RegisteringInfo.checkin = TRUE AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE
          AND tuts_rest.RegisteringInfo.checkResult IS NULL
          AND tuts_rest.RegisteringInfo.registerNumber != actualServing
        GROUP BY tuts_rest.RegisteringInfo.registerNumber
        ORDER BY tuts_rest.RegisteringInfo.registerNumber ASC
        LIMIT 1;
        -- 2. if there is one presenseNumber which is already check in today for this doctor
        IF countResult > 0 THEN
          set nextNumber = registerNumber;
          select nextNumber;
          LEAVE ThisSP;
        ELSE
          BEGIN
            SELECT COUNT (tuts_rest.RegisteringInfo.registerNumber), tuts_rest.RegisteringInfo.registerNumber into countResult, registerNumber
            FROM tuts_rest.RegisteringInfo
            WHERE tuts_rest.RegisteringInfo.registerNumber < tuts_rest.getSeatSeperator() AND tuts_rest.RegisteringInfo.doctorID = doctorID
              AND tuts_rest.RegisteringInfo.checkin = TRUE AND tuts_rest.RegisteringInfo.targetDate = CURRENT_DATE
              AND tuts_rest.RegisteringInfo.checkResult IS NULL
              AND tuts_rest.RegisteringInfo.registerNumber != actualServing
            GROUP BY tuts_rest.RegisteringInfo.registerNumber
            ORDER BY tuts_rest.RegisteringInfo.registerNumber ASC
            LIMIT 1;
            -- 3. if there is NO presenseNumber is being checked in --> PRIO go to the next seatID in case (s)he already checked in
            IF countResult > 0 THEN
              set nextNumber = registerNumber;
              select nextNumber;
              LEAVE ThisSP;
            ELSE
              BEGIN
                set nextNumber = -1;
                select nextNumber;
                LEAVE ThisSP;
              END;
            END IF;
          END;
        END IF;
      END;
    END IF;
    set nextNumber = -1;
    select nextNumber;
END

DROP PROCEDURE IF EXISTS `getServingNumber`
CREATE DEFINER=`root`@`localhost` PROCEDURE `getServingNumber` (IN `doctorID` BIGINT)
BEGIN
    DECLARE servingNumber SMALLINT DEFAULT -1;
    SELECT DoctorInfo.actualServing INTO servingNumber
    FROM tuts_rest.DoctorInfo
    WHERE tuts_rest.DoctorInfo.doctorID = doctorID;

    SELECT servingNumber;
END

DROP FUNCTION IF EXISTS `getSeatStatus`
CREATE DEFINER=`root`@`localhost` FUNCTION `getSeatStatus` (`doctorID` INT, `seatID` SMALLINT)
RETURNS TINYINT
BEGIN
  DECLARE count TINYINT;
  DECLARE seatStatus TINYINT;

  SELECT COUNT(tuts_rest.SeatAvailable.id) into count FROM tuts_rest.SeatAvailable
    WHERE SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;
  IF count < 1 THEN
      RETURN tuts_rest.RET_SEAT_OUT_OF_RANGE();
  END IF;

  SELECT COUNT(tuts_rest.SeatAvailable.id) INTO count
    FROM  tuts_rest.SeatAvailable
    WHERE tuts_rest.SeatAvailable.doctorID = doctorID AND tuts_rest.SeatAvailable.seatID = seatID
      AND tuts_rest.SeatAvailable.day != CURRENT_DATE;
  IF count > 0 THEN
        RETURN tuts_rest.CONST_AVAILABLE();
  END IF;

  SELECT tuts_rest.SeatAvailable.status INTO seatStatus FROM tuts_rest.SeatAvailable
    WHERE SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID
      AND tuts_rest.SeatAvailable.day = CURRENT_DATE;

  RETURN seatStatus;

CREATE DEFINER=`root`@`localhost` PROCEDURE `addAvailableSeat` (IN `doctorID` INT)  BEGIN
    DECLARE count INT DEFAULT 1;
    start transaction;
      while count < 200 do
        insert into SeatAvailable (doctorID, seatID, status, day) values (doctorID, count, 0, CURRENT_DATE);
        set count = count + 1;
      end while;
    commit;
END

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteAvailableSeat` (IN `doctorID` INT)  BEGIN
    DECLARE count INT DEFAULT 1;
    DELETE FROM SeatAvailable WHERE SeatAvailable.doctorID = doctorID;
END$$

DROP FUNCTION IF EXISTS `getSeatSeperator`
CREATE DEFINER=`root`@`localhost` FUNCTION `getSeatSeperator` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 100;
END

DROP FUNCTION IF EXISTS `CONST_AVAILABLE`
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_AVAILABLE` ()
RETURNS TINYINT
BEGIN
RETURN 0;
END

DROP FUNCTION IF EXISTS `RET_SEAT_NOT_AVAILABLE`
CREATE DEFINER=`root`@`localhost` FUNCTION `RET_SEAT_NOT_AVAILABLE` ()
RETURNS TINYINT
BEGIN
RETURN 0;
END

DROP FUNCTION IF EXISTS `CONST_BOOKED`
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_BOOKED` ()
RETURNS TINYINT
BEGIN
RETURN 1;
END

DROP FUNCTION IF EXISTS `RET_BOOK_OK`
CREATE DEFINER=`root`@`localhost` FUNCTION `RET_BOOK_OK` ()
RETURNS TINYINT
BEGIN
RETURN 1;
END

DROP FUNCTION IF EXISTS `RET_DAY_OFF`
CREATE DEFINER=`root`@`localhost` FUNCTION `RET_DAY_OFF` ()
RETURNS TINYINT
BEGIN
RETURN -2;
END

DROP FUNCTION IF EXISTS `CONST_CHECKED`
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_CHECKED` ()
RETURNS TINYINT
BEGIN
RETURN 1;
END

DROP FUNCTION IF EXISTS `CONST_SKIPPED`
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_SKIPPED` ()
RETURNS TINYINT
BEGIN
RETURN -1;
END

DROP FUNCTION IF EXISTS `RET_ALREADY_REGISTER`
CREATE DEFINER=`root`@`localhost` FUNCTION `RET_ALREADY_REGISTER` ()
RETURNS TINYINT
BEGIN
RETURN -1;
END

DROP FUNCTION IF EXISTS `RET_SEAT_OUT_OF_RANGE`
CREATE DEFINER=`root`@`localhost` FUNCTION `RET_SEAT_OUT_OF_RANGE` ()
RETURNS TINYINT
BEGIN
RETURN -3;
END


END
