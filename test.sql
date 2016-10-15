
DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `bookASeat` (IN `userID` VARCHAR(20), `doctorID` INT, `seatID` SMALLINT)
ThisSP:BEGIN
  	DECLARE registerNumber INT default 1;
    DECLARE dayOff INT default 1;
    DECLARE seatStatus BOOL DEFAULT FALSE;

    -- RETURN
    -- -2: Day OFF
    -- -1: User already register
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
    SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;

    IF registerNumber > 0 THEN
        SELECT -1;
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
        insert into SeatAvailable (doctorID, seat, status, day) values (doctorID, count, 0, CURRENT_DATE);
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


call isUserRegisteredToday('isUserRegisteredToday')

call registerANumber('1234')
call checkin('1234')

UPDATE RegisteringInfo SET checkin = 1, alreadyChecked = 1 where id = 30
