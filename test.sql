
call requestAPresenseNumber('123',1)

call bookASeat('123',1,4)

SELECT tuts_rest.SeatAvailable.seatID, tuts_rest.SeatAvailable.status, tuts_rest.SeatAvailable.day
FROM tuts_rest.SeatAvailable
WHERE tuts_rest.SeatAvailable.doctorID = 1 AND tuts_rest.SeatAvailable.seatID < tuts_rest.getSeatSeperator()

call getSeats(1)

CREATE DEFINER=`root`@`localhost` PROCEDURE `getSeats` (IN `doctorID` INT)
BEGIN
    SELECT tuts_rest.SeatAvailable.seatID, tuts_rest.SeatAvailable.status, tuts_rest.SeatAvailable.day
    FROM tuts_rest.SeatAvailable
    WHERE tuts_rest.SeatAvailable.doctorID = doctorID AND tuts_rest.SeatAvailable.seatID < tuts_rest.getSeatSeperator();
END



DELIMITER $$
--
-- Procedures
--

DROP PROCEDURE IF EXISTS bookASeat

CREATE DEFINER=`root`@`localhost` PROCEDURE `bookASeat` (IN `userID` VARCHAR(20), `doctorID` INT, `seatID` SMALLINT)
ThisSP:BEGIN
  	DECLARE registerNumber INT default 1;
    DECLARE dayOff INT default 1;
    DECLARE seatStatus BOOL DEFAULT FALSE;
    DECLARE seatAvailableID BIGINT DEFAULT 0;

    -- RETURN
    -- -2: Day OFF
    -- -1: User already register
    -- -3: Out of range
    -- 0: Seat is not available
    -- 1: Seat is available and it's booked

    -- DAY OFF : RETURN -2
    SELECT COUNT(doctorID) INTO dayOff
    FROM NonCheckingDay
    WHERE NonCheckingDay.doctorID = doctorID AND NonCheckingDay.day = CURRENT_DATE;

    IF dayOff > 0 THEN
        SELECT -2;
        LEAVE ThisSP;
    END IF;

    -- ALREADY REGISTER -1
    SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo
    WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE
          AND RegisteringInfo.registerNumber < getSeatSeperator() AND RegisteringInfo.alreadyChecked >=0;

    IF registerNumber > 0 THEN

        SELECT -1;
        LEAVE ThisSP;
    END IF;

    -- SEAT REQUESTED IS OUT OF RANGE
    SELECT COUNT(SeatAvailable.id) INTO seatAvailableID FROM SeatAvailable
    WHERE SeatAvailable.doctorID = doctorID AND tuts_rest.SeatAvailable.seatID = seatID
          AND tuts_rest.SeatAvailable.seatID < tuts_rest.getSeatSeperator();

    IF seatAvailableID < 1 THEN
        SELECT -3;
        LEAVE ThisSP;
    END IF;

    -- SEAT NOT AVAILABLE: RETURN 0
    SELECT SeatAvailable.status INTO seatStatus FROM SeatAvailable
    WHERE day = CURRENT_DATE AND SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;

    IF seatStatus THEN
      SELECT 0;
      LEAVE ThisSP;
    ELSE
      -- SEAT AVAILABLE: RETURN 1
      START TRANSACTION;
          UPDATE SeatAvailable SET SeatAvailable.status = 1, SeatAvailable.day = CURRENT_DATE
          WHERE SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;

          INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId, doctorID, registerNumber)
                  VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID, doctorID, seatID);
          SELECT 1;
      COMMIT;
    END IF;
END


DELIMITER ;


DELIMITER $$
--
-- Procedures
--
DROP PROCEDURE IF EXISTS requestAPresenseNumber
CREATE DEFINER=`root`@`localhost` PROCEDURE `requestANumber` (IN `userID` VARCHAR(20), IN `doctorID` INT)
BEGIN
    DECLARE ID BIGINT;
    DECLARE seatID SMALLINT;

    SELECT SeatAvailable.id, SeatAvailable.seatID INTO ID, seatID FROM tuts_rest.SeatAvailable
    WHERE SeatAvailable.seatID  > getSeatSeperator() AND SeatAvailable.doctorID = doctorID
          AND (SeatAvailable.day < CURRENT_DATE OR (SeatAvailable.day = CURRENT_DATE AND tuts_rest.SeatAvailable.status <>1))
    ORDER BY SeatAvailable.seatID LIMIT 1;

    START TRANSACTION;
        UPDATE tuts_rest.SeatAvailable SET SeatAvailable.status = 1, day = CURRENT_DATE WHERE tuts_rest.SeatAvailable.id = ID;
        INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId, doctorID, registerNumber)
                VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID, doctorID, seatID);
        SELECT seatID;
    COMMIT;
END

DELIMITER ;


DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `registerANumber` (IN `userID` VARCHAR(20), IN `doctorID` INT)
ThisSP:BEGIN
  	DECLARE registerNumber INT default 1;
    DECLARE dayOff INT default 1;

    SELECT COUNT(doctorID) INTO dayOff
    FROM NonCheckingDay
    WHERE NonCheckingDay.doctorID = doctorID AND NonCheckingDay.day = CURRENT_DATE;

    IF dayOff > 0 THEN
        SELECT -1;
        LEAVE ThisSP;
    END IF;

    SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;

    IF registerNumber < 1 THEN
      	INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId, doctorID) VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID, doctorID);
        SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE targetDate = CURRENT_DATE AND id < LAST_INSERT_ID();
        SET registerNumber = registerNumber + 1;
        UPDATE RegisteringInfo set RegisteringInfo.registerNumber = registerNumber WHERE targetDate = CURRENT_DATE AND RegisteringInfo.userId = userID;
    ELSE
        SELECT RegisteringInfo.registerNumber INTO registerNumber FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;
    END IF;
    select registerNumber;
END

DELIMITER ;


DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `isUserRegisteredToday` (IN `userID` VARCHAR(20))  BEGIN
  		DECLARE countRecord INT default 0;
        SELECT COUNT(id) INTO countRecord FROM RegisteringInfo WHERE targetDate = CURRENT_DATE AND RegisteringInfo.userID = userID;
        select countRecord;
END$$

DELIMITER ;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `checkIn` (IN `userID` VARCHAR(20))  BEGIN
    UPDATE RegisteringInfo set checkin = TRUE, checkintime = CURRENT_TIMESTAMP WHERE targetDate = CURRENT_DATE AND RegisteringInfo.userId = userID;
END$$

DELIMITER ;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `getCurrentAndNext` (IN `doctorID` INT)  BEGIN
    SELECT registerNumber FROM RegisteringInfo
    WHERE RegisteringInfo.doctorID = doctorID AND checkin = 1
          AND targetDate = CURRENT_DATE AND DATE(checkintime) = CURRENT_DATE
          AND alreadyChecked = 0
    ORDER BY checkintime
    LIMIT 2;
END$$

DELIMITER ;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `getWaitingList` (IN `doctorID` INT)  BEGIN
    SELECT registerNumber FROM RegisteringInfo
    WHERE RegisteringInfo.doctorID = doctorID AND checkin = 1
        AND targetDate = CURRENT_DATE AND DATE(checkintime) = CURRENT_DATE
        AND alreadyChecked = 0
    ORDER BY checkintime;
END$$

DELIMITER ;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `goToNext` (IN `doctorID` INT, `nextOrSkip` TINYINT)  BEGIN
    DECLARE id BIGINT;
    SELECT RegisteringInfo.ID INTO id FROM RegisteringInfo
    WHERE RegisteringInfo.doctorID = doctorID AND checkin = 1
          AND targetDate = CURRENT_DATE AND DATE(checkintime) = CURRENT_DATE
          AND alreadyChecked = 0
    ORDER BY checkintime
    LIMIT 1;
    UPDATE RegisteringInfo SET alreadyChecked = nextOrSkip WHERE RegisteringInfo.id = id;
END$$

DELIMITER ;


DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `addAvailableSeat` (IN `doctorID` INT)  BEGIN
    DECLARE count INT DEFAULT 1;
    start transaction;
      while count < 200 do
        insert into SeatAvailable (doctorID, seatID, status, day) values (doctorID, count, 0, CURRENT_DATE);
        set count = count + 1;
      end while;
    commit;
END$$

DELIMITER ;

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteAvailableSeat` (IN `doctorID` INT)  BEGIN
    DECLARE count INT DEFAULT 1;
    DELETE FROM SeatAvailable WHERE SeatAvailable.doctorID = doctorID;
END$$

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS getSeatSeperator
CREATE DEFINER=`root`@`localhost` FUNCTION `getSeatSeperator` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 100;
END

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS CONST_AVAILABLE
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_AVAILABLE` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 0;
END

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS CONST_BOOKED
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_BOOKED` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 1;
END

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS CONST_CHECKED
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_CHECKED` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 2;
END

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS CONST_SKIPPED
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_SKIPPED` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 3;
END

DELIMITER ;

DELIMITER $$

DROP FUNCTION IF EXISTS CONST_OUT_OF_RANGE
CREATE DEFINER=`root`@`localhost` FUNCTION `CONST_OUT_OF_RANGE` ()
RETURNS TINYINT UNSIGNED
BEGIN
RETURN 4;
END

DELIMITER ;


DELIMITER $$

DROP FUNCTION IF EXISTS getSeatStatus
CREATE DEFINER=`root`@`localhost` FUNCTION `getSeatStatus` (`doctorID` INT, `seatID` SMALLINT)
RETURNS TINYINT UNSIGNED
BEGIN
  DECLARE count TINYINT;
  DECLARE seatStatus TINYINT;

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

END

DELIMITER ;

UPDATE tuts_rest.SeatAvailable SET SeatAvailable.status = tuts_rest.CONST_CHECKED()
  WHERE tuts_rest.SeatAvailable.doctorID = 1 AND tuts_rest.SeatAvailable.day = CURRENT_DATE

IF tuts_rest.getSeatStatus(1,4) = tuts_rest.CONST_AVAILABLE() THEN
  SELECT "AVAILABLE";
ELSEIF tuts_rest.getSeatStatus(1,4) = tuts_rest.CONST_BOOKED() THEN
  SELECT "BOOOKED";
ELSEIF tuts_rest.getSeatStatus(1,4) = tuts_rest.CONST_SKIPPED() THEN
  SELECT "SKIPPED";
ELSEIF tuts_rest.getSeatStatus(1,4) = tuts_rest.CONST_CHECKED() THEN
  SELECT "CHECKED";
ELSEIF tuts_rest.getSeatStatus(1,4) = tuts_rest.CONST_OUT_OF_RANGE() THEN
  SELECT "OUT OF RANGE";
END IF


call isUserRegisteredToday('isUserRegisteredToday')

call registerANumber('1234')
call checkin('1234')

UPDATE RegisteringInfo SET checkin = 1, alreadyChecked = 1 where id = 30
