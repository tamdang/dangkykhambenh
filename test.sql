
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
    WHERE NonCheckingDay.doctorID = doctorID AND NonCheckingDay.date = CURRENT_DATE;

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

call isUserRegisteredToday('isUserRegisteredToday')

call registerANumber('1234')
call checkin('1234')

UPDATE RegisteringInfo SET checkin = 1, alreadyChecked = 1 where id = 30
