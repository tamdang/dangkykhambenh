BEGIN
  	DECLARE registerNumber INT default 1;
    DECLARE alreadyRegister INT default 0;
    DECLARE recordID INT default 0;

    SELECT COUNT(ID) INTO alreadyRegister FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;

    IF alreadyRegister > 0 THEN
		    SELECT ID INTO recordID FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;
        --SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE targetDate = CURRENT_DATE AND id < recordID;
        SELECT RegisteringInfo.registerNumber into registerNumber where targetDate = CURRENT_DATE AND id = recordID;
        --SELECT registerNumber;
	  ELSE
      	INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId) VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID);
        SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE targetDate = CURRENT_DATE AND id < LAST_INSERT_ID();
        SET registerNumber = registerNumber + 1;
        UPDATE RegisteringInfo set RegisteringInfo.registerNumber = registerNumber
        select registerNumber;
    END IF;
ENDr


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

call isUserRegisteredToday('isUserRegisteredToday')
