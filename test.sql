BEGIN
  	DECLARE registerNumber INT default 1;

    SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;

    IF registerNumber < 1 THEN
      	INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId) VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID);
        SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE targetDate = CURRENT_DATE AND id < LAST_INSERT_ID();
        SET registerNumber = registerNumber + 1;
        UPDATE RegisteringInfo set RegisteringInfo.registerNumber = registerNumber WHERE targetDate = CURRENT_DATE AND RegisteringInfo.userId = userID;
    ELSE
        SELECT RegisteringInfo.registerNumber INTO registerNumber FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;
    END IF;
    select registerNumber;
END


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


call isUserRegisteredToday('isUserRegisteredToday')
