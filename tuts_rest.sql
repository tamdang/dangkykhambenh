-- phpMyAdmin SQL Dump
-- version 4.5.2
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Oct 15, 2016 at 10:04 AM
-- Server version: 10.1.16-MariaDB
-- PHP Version: 5.6.24

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tuts_rest`
--

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

CREATE DEFINER=`root`@`localhost` PROCEDURE `bookASeat` (IN `userID` VARCHAR(20), IN `doctorID` INT, IN `seatID` SMALLINT)  ThisSP: BEGIN
  	DECLARE registerNumber INT default 1;
    DECLARE dayOff INT default 1;
    DECLARE seatStatus BOOL DEFAULT FALSE;

        SELECT COUNT(doctorID) INTO dayOff
    FROM NonCheckingDay
    WHERE NonCheckingDay.doctorID = doctorID AND NonCheckingDay.day = CURRENT_DATE;

    IF dayOff > 0 THEN
        SELECT -2;
        LEAVE ThisSP;
    END IF;

        SELECT COUNT(id) INTO registerNumber FROM RegisteringInfo WHERE RegisteringInfo.userId = userId AND targetDate = CURRENT_DATE;

    IF registerNumber > 0 THEN
        SELECT -1;
        LEAVE ThisSP;
    END IF;

        SELECT SeatAvailable.status INTO seatStatus FROM SeatAvailable
    WHERE day = CURRENT_DATE AND SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;

    IF seatStatus THEN
      SELECT 0;
      LEAVE ThisSP;
    ELSE
            START TRANSACTION;
          UPDATE SeatAvailable SET SeatAvailable.status = 1, SeatAvailable.day = CURRENT_DATE
          WHERE SeatAvailable.doctorID = doctorID AND SeatAvailable.seatID = seatID;

          INSERT INTO RegisteringInfo (id, registeringTime, targetDate, userId, doctorID, registerNumber)
                  VALUES (NULL, CURRENT_TIME, CURRENT_DATE, userID, doctorID, seatID);
          SELECT 1;
      COMMIT;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `checkIn` (IN `userID` VARCHAR(20))  BEGIN
    UPDATE RegisteringInfo set checkin = TRUE, checkintime = CURRENT_TIMESTAMP WHERE targetDate = CURRENT_DATE AND RegisteringInfo.userId = userID; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteAvailableSeat` (IN `doctorID` INT)  BEGIN
    DECLARE count INT DEFAULT 1;
    DELETE FROM SeatAvailable WHERE SeatAvailable.doctorID = doctorID;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getCurrentAndNext` (IN `doctorID` INT)  BEGIN
    SELECT registerNumber FROM RegisteringInfo
    WHERE RegisteringInfo.doctorID = doctorID
          AND checkin = 1 AND targetDate = CURRENT_DATE
          AND DATE(checkintime) = CURRENT_DATE AND alreadyChecked = 0
    ORDER BY checkintime
    LIMIT 2;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getWaitingList` (IN `doctorID` INT)  BEGIN
    SELECT registerNumber FROM RegisteringInfo
    WHERE RegisteringInfo.doctorID = doctorID AND checkin = 1
        AND targetDate = CURRENT_DATE AND DATE(checkintime) = CURRENT_DATE
        AND alreadyChecked = 0
    ORDER BY checkintime;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `goToNext` (IN `doctorID` INT, IN `checkOrSkip` TINYINT)  BEGIN
    DECLARE id BIGINT;
    SELECT RegisteringInfo.ID INTO id FROM RegisteringInfo
    WHERE RegisteringInfo.doctorID = doctorID AND checkin = 1
          AND targetDate = CURRENT_DATE AND DATE(checkintime) = CURRENT_DATE
          AND alreadyChecked = 0
    ORDER BY checkintime
    LIMIT 1;
    UPDATE RegisteringInfo SET alreadyChecked = checkOrSkip WHERE RegisteringInfo.id = id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `isUserRegisteredToday` (IN `userID` VARCHAR(20))  BEGIN
  		DECLARE countRecord INT default 0;
        SELECT COUNT(id) INTO countRecord FROM RegisteringInfo WHERE targetDate = CURRENT_DATE AND RegisteringInfo.userID = userID;
        select countRecord;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerANumber` (IN `userID` VARCHAR(20), IN `doctorID` INT)  ThisSP:BEGIN
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
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `CheckingInfo`
--

CREATE TABLE `CheckingInfo` (
  `date` date NOT NULL,
  `currentNumber` int(11) NOT NULL,
  `nextNumber` int(11) NOT NULL,
  `doctorID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `DoctorInfo`
--

CREATE TABLE `DoctorInfo` (
  `doctorID` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `address` varchar(250) NOT NULL,
  `longtitude` varchar(10) NOT NULL,
  `latitutue` varchar(10) NOT NULL,
  `startTime` time NOT NULL,
  `endTime` time NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `NonCheckingDay`
--

CREATE TABLE `NonCheckingDay` (
  `doctorID` int(11) NOT NULL,
  `day` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `NonCheckingDay`
--

INSERT INTO `NonCheckingDay` (`doctorID`, `day`) VALUES
(1, '2016-10-14');

-- --------------------------------------------------------

--
-- Table structure for table `RegisteringInfo`
--

CREATE TABLE `RegisteringInfo` (
  `id` bigint(20) NOT NULL,
  `userId` char(20) NOT NULL,
  `registeringTime` time NOT NULL,
  `targetDate` date NOT NULL,
  `registerNumber` int(11) NOT NULL,
  `checkin` tinyint(1) NOT NULL DEFAULT '0',
  `checkintime` datetime NOT NULL,
  `alreadyChecked` tinyint(1) NOT NULL DEFAULT '0',
  `doctorID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `RegisteringInfo`
--

INSERT INTO `RegisteringInfo` (`id`, `userId`, `registeringTime`, `targetDate`, `registerNumber`, `checkin`, `checkintime`, `alreadyChecked`, `doctorID`) VALUES
(24, '1234', '06:26:38', '2016-10-13', 0, 1, '0000-00-00 00:00:00', 0, 0),
(25, '123456', '06:33:51', '2016-10-13', 2, 1, '2016-10-13 06:58:39', 0, 0),
(26, '1234567', '06:38:17', '2016-10-13', 3, 1, '2016-10-13 06:58:57', 0, 0),
(27, '12345678', '06:38:40', '2016-10-13', 4, 1, '0000-00-00 00:00:00', 0, 0),
(28, '123456789', '06:38:50', '2016-10-13', 5, 1, '0000-00-00 00:00:00', 0, 0),
(29, '10210678223980910', '06:48:16', '2016-10-13', 6, 1, '0000-00-00 00:00:00', -1, 0),
(30, '123', '05:49:52', '2016-10-14', 1, 1, '2016-10-14 05:52:51', 1, 0),
(31, '1234', '05:54:43', '2016-10-14', 2, 1, '2016-10-14 06:01:59', -1, 0),
(32, '12345', '06:02:19', '2016-10-14', 3, 1, '2016-10-14 06:02:28', 1, 0),
(33, '123456', '09:08:00', '2016-10-14', 4, 1, '2016-10-14 09:08:18', 0, 0),
(34, '1234567', '09:10:15', '2016-10-14', 5, 1, '2016-10-14 09:10:24', 0, 0),
(35, '12345678', '09:13:33', '2016-10-14', 6, 1, '2016-10-14 09:14:08', 0, 0),
(36, '123456789', '09:13:40', '2016-10-14', 7, 1, '2016-10-14 09:14:02', 0, 0),
(37, '2468', '18:38:05', '2016-10-14', 8, 0, '0000-00-00 00:00:00', 0, 0),
(38, '0123', '18:56:23', '2016-10-14', 9, 0, '0000-00-00 00:00:00', 0, 1),
(39, '10210678223980910', '19:10:38', '2016-10-14', 10, 0, '0000-00-00 00:00:00', 0, 0),
(40, '', '21:01:43', '2016-10-14', 11, 0, '0000-00-00 00:00:00', 0, 0),
(41, '123', '14:16:59', '2016-10-15', 1, 0, '0000-00-00 00:00:00', 0, 1),
(42, '1234', '14:51:21', '2016-10-15', 2, 0, '0000-00-00 00:00:00', 0, 1),
(43, '12345', '14:56:11', '2016-10-15', 3, 0, '0000-00-00 00:00:00', 0, 1);

-- --------------------------------------------------------

--
-- Table structure for table `SeatAvailable`
--

CREATE TABLE `SeatAvailable` (
  `doctorID` int(11) NOT NULL,
  `seatID` smallint(6) NOT NULL,
  `status` tinyint(1) NOT NULL,
  `day` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dumping data for table `SeatAvailable`
--

INSERT INTO `SeatAvailable` (`doctorID`, `seatID`, `status`, `day`) VALUES
(1, 1, 1, '2016-10-15'),
(1, 2, 1, '2016-10-15'),
(1, 3, 1, '2016-10-15'),
(1, 4, 0, '2016-10-15'),
(1, 5, 0, '2016-10-15'),
(1, 6, 0, '2016-10-15'),
(1, 7, 0, '2016-10-15'),
(1, 8, 0, '2016-10-15'),
(1, 9, 0, '2016-10-15'),
(1, 10, 0, '2016-10-15'),
(1, 11, 0, '2016-10-15'),
(1, 12, 0, '2016-10-15'),
(1, 13, 0, '2016-10-15'),
(1, 14, 0, '2016-10-15'),
(1, 15, 0, '2016-10-15'),
(1, 16, 0, '2016-10-15'),
(1, 17, 0, '2016-10-15'),
(1, 18, 0, '2016-10-15'),
(1, 19, 0, '2016-10-15'),
(1, 20, 0, '2016-10-15'),
(1, 21, 0, '2016-10-15'),
(1, 22, 0, '2016-10-15'),
(1, 23, 0, '2016-10-15'),
(1, 24, 0, '2016-10-15'),
(1, 25, 0, '2016-10-15'),
(1, 26, 0, '2016-10-15'),
(1, 27, 0, '2016-10-15'),
(1, 28, 0, '2016-10-15'),
(1, 29, 0, '2016-10-15'),
(1, 30, 0, '2016-10-15'),
(1, 31, 0, '2016-10-15'),
(1, 32, 0, '2016-10-15'),
(1, 33, 0, '2016-10-15'),
(1, 34, 0, '2016-10-15'),
(1, 35, 0, '2016-10-15'),
(1, 36, 0, '2016-10-15'),
(1, 37, 0, '2016-10-15'),
(1, 38, 0, '2016-10-15'),
(1, 39, 0, '2016-10-15'),
(1, 40, 0, '2016-10-15'),
(1, 41, 0, '2016-10-15'),
(1, 42, 0, '2016-10-15'),
(1, 43, 0, '2016-10-15'),
(1, 44, 0, '2016-10-15'),
(1, 45, 0, '2016-10-15'),
(1, 46, 0, '2016-10-15'),
(1, 47, 0, '2016-10-15'),
(1, 48, 0, '2016-10-15'),
(1, 49, 0, '2016-10-15'),
(1, 50, 0, '2016-10-15'),
(1, 51, 0, '2016-10-15'),
(1, 52, 0, '2016-10-15'),
(1, 53, 0, '2016-10-15'),
(1, 54, 0, '2016-10-15'),
(1, 55, 0, '2016-10-15'),
(1, 56, 0, '2016-10-15'),
(1, 57, 0, '2016-10-15'),
(1, 58, 0, '2016-10-15'),
(1, 59, 0, '2016-10-15'),
(1, 60, 0, '2016-10-15'),
(1, 61, 0, '2016-10-15'),
(1, 62, 0, '2016-10-15'),
(1, 63, 0, '2016-10-15'),
(1, 64, 0, '2016-10-15'),
(1, 65, 0, '2016-10-15'),
(1, 66, 0, '2016-10-15'),
(1, 67, 0, '2016-10-15'),
(1, 68, 0, '2016-10-15'),
(1, 69, 0, '2016-10-15'),
(1, 70, 0, '2016-10-15'),
(1, 71, 0, '2016-10-15'),
(1, 72, 0, '2016-10-15'),
(1, 73, 0, '2016-10-15'),
(1, 74, 0, '2016-10-15'),
(1, 75, 0, '2016-10-15'),
(1, 76, 0, '2016-10-15'),
(1, 77, 0, '2016-10-15'),
(1, 78, 0, '2016-10-15'),
(1, 79, 0, '2016-10-15'),
(1, 80, 0, '2016-10-15'),
(1, 81, 0, '2016-10-15'),
(1, 82, 0, '2016-10-15'),
(1, 83, 0, '2016-10-15'),
(1, 84, 0, '2016-10-15'),
(1, 85, 0, '2016-10-15'),
(1, 86, 0, '2016-10-15'),
(1, 87, 0, '2016-10-15'),
(1, 88, 0, '2016-10-15'),
(1, 89, 0, '2016-10-15'),
(1, 90, 0, '2016-10-15'),
(1, 91, 0, '2016-10-15'),
(1, 92, 0, '2016-10-15'),
(1, 93, 0, '2016-10-15'),
(1, 94, 0, '2016-10-15'),
(1, 95, 0, '2016-10-15'),
(1, 96, 0, '2016-10-15'),
(1, 97, 0, '2016-10-15'),
(1, 98, 0, '2016-10-15'),
(1, 99, 0, '2016-10-15'),
(1, 100, 0, '2016-10-15'),
(1, 101, 0, '2016-10-15'),
(1, 102, 0, '2016-10-15'),
(1, 103, 0, '2016-10-15'),
(1, 104, 0, '2016-10-15'),
(1, 105, 0, '2016-10-15'),
(1, 106, 0, '2016-10-15'),
(1, 107, 0, '2016-10-15'),
(1, 108, 0, '2016-10-15'),
(1, 109, 0, '2016-10-15'),
(1, 110, 0, '2016-10-15'),
(1, 111, 0, '2016-10-15'),
(1, 112, 0, '2016-10-15'),
(1, 113, 0, '2016-10-15'),
(1, 114, 0, '2016-10-15'),
(1, 115, 0, '2016-10-15'),
(1, 116, 0, '2016-10-15'),
(1, 117, 0, '2016-10-15'),
(1, 118, 0, '2016-10-15'),
(1, 119, 0, '2016-10-15'),
(1, 120, 0, '2016-10-15'),
(1, 121, 0, '2016-10-15'),
(1, 122, 0, '2016-10-15'),
(1, 123, 0, '2016-10-15'),
(1, 124, 0, '2016-10-15'),
(1, 125, 0, '2016-10-15'),
(1, 126, 0, '2016-10-15'),
(1, 127, 0, '2016-10-15'),
(1, 128, 0, '2016-10-15'),
(1, 129, 0, '2016-10-15'),
(1, 130, 0, '2016-10-15'),
(1, 131, 0, '2016-10-15'),
(1, 132, 0, '2016-10-15'),
(1, 133, 0, '2016-10-15'),
(1, 134, 0, '2016-10-15'),
(1, 135, 0, '2016-10-15'),
(1, 136, 0, '2016-10-15'),
(1, 137, 0, '2016-10-15'),
(1, 138, 0, '2016-10-15'),
(1, 139, 0, '2016-10-15'),
(1, 140, 0, '2016-10-15'),
(1, 141, 0, '2016-10-15'),
(1, 142, 0, '2016-10-15'),
(1, 143, 0, '2016-10-15'),
(1, 144, 0, '2016-10-15'),
(1, 145, 0, '2016-10-15'),
(1, 146, 0, '2016-10-15'),
(1, 147, 0, '2016-10-15'),
(1, 148, 0, '2016-10-15'),
(1, 149, 0, '2016-10-15'),
(1, 150, 0, '2016-10-15'),
(1, 151, 0, '2016-10-15'),
(1, 152, 0, '2016-10-15'),
(1, 153, 0, '2016-10-15'),
(1, 154, 0, '2016-10-15'),
(1, 155, 0, '2016-10-15'),
(1, 156, 0, '2016-10-15'),
(1, 157, 0, '2016-10-15'),
(1, 158, 0, '2016-10-15'),
(1, 159, 0, '2016-10-15'),
(1, 160, 0, '2016-10-15'),
(1, 161, 0, '2016-10-15'),
(1, 162, 0, '2016-10-15'),
(1, 163, 0, '2016-10-15'),
(1, 164, 0, '2016-10-15'),
(1, 165, 0, '2016-10-15'),
(1, 166, 0, '2016-10-15'),
(1, 167, 0, '2016-10-15'),
(1, 168, 0, '2016-10-15'),
(1, 169, 0, '2016-10-15'),
(1, 170, 0, '2016-10-15'),
(1, 171, 0, '2016-10-15'),
(1, 172, 0, '2016-10-15'),
(1, 173, 0, '2016-10-15'),
(1, 174, 0, '2016-10-15'),
(1, 175, 0, '2016-10-15'),
(1, 176, 0, '2016-10-15'),
(1, 177, 0, '2016-10-15'),
(1, 178, 0, '2016-10-15'),
(1, 179, 0, '2016-10-15'),
(1, 180, 0, '2016-10-15'),
(1, 181, 0, '2016-10-15'),
(1, 182, 0, '2016-10-15'),
(1, 183, 0, '2016-10-15'),
(1, 184, 0, '2016-10-15'),
(1, 185, 0, '2016-10-15'),
(1, 186, 0, '2016-10-15'),
(1, 187, 0, '2016-10-15'),
(1, 188, 0, '2016-10-15'),
(1, 189, 0, '2016-10-15'),
(1, 190, 0, '2016-10-15'),
(1, 191, 0, '2016-10-15'),
(1, 192, 0, '2016-10-15'),
(1, 193, 0, '2016-10-15'),
(1, 194, 0, '2016-10-15'),
(1, 195, 0, '2016-10-15'),
(1, 196, 0, '2016-10-15'),
(1, 197, 0, '2016-10-15'),
(1, 198, 0, '2016-10-15'),
(1, 199, 0, '2016-10-15');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `DoctorInfo`
--
ALTER TABLE `DoctorInfo`
  ADD PRIMARY KEY (`doctorID`);

--
-- Indexes for table `RegisteringInfo`
--
ALTER TABLE `RegisteringInfo`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `SeatAvailable`
--
ALTER TABLE `SeatAvailable`
  ADD KEY `doctorID` (`doctorID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `DoctorInfo`
--
ALTER TABLE `DoctorInfo`
  MODIFY `doctorID` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `RegisteringInfo`
--
ALTER TABLE `RegisteringInfo`
  MODIFY `id` bigint(20) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=44;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
