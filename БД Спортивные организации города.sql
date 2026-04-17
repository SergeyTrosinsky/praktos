-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1:3306
-- Время создания: Дек 19 2025 г., 12:51
-- Версия сервера: 8.0.30
-- Версия PHP: 7.2.34

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `SportInfrastruktura`
--

DELIMITER $$
--
-- Процедуры
--
CREATE DEFINER=`root`@`%` PROCEDURE `GetKlubyIAktivnost` (IN `p_data_nachala` DATE, IN `p_data_konca` DATE)   BEGIN
    SELECT 
        Sportivnye_kluby.Nazvanie AS Klub,
        COUNT(DISTINCT Sportsmeny.ID) AS Vsego_sportsmenov_v_klube,
        COUNT(DISTINCT CASE 
            WHEN Rezultaty_uchastiya.ID IS NOT NULL 
            AND (p_data_nachala IS NULL OR Sostyazaniya.Data_provedeniya >= p_data_nachala)
            AND (p_data_konca IS NULL OR Sostyazaniya.Data_provedeniya <= p_data_konca)
            THEN Sportsmeny.ID 
        END) AS Sportsmenov_v_sorevnovaniyah,
        COUNT(DISTINCT CASE 
            WHEN Rezultaty_uchastiya.ID IS NOT NULL 
            AND Rezultaty_uchastiya.Mesto = 1
            AND (p_data_nachala IS NULL OR Sostyazaniya.Data_provedeniya >= p_data_nachala)
            AND (p_data_konca IS NULL OR Sostyazaniya.Data_provedeniya <= p_data_konca)
            THEN Sportsmeny.ID 
        END) AS Sportsmenov_pobediteley
    FROM Sportivnye_kluby
    LEFT JOIN Sportsmeny ON Sportivnye_kluby.ID_sportivnogo_kluba = Sportsmeny.ID_sportivnogo_kluba
    LEFT JOIN Rezultaty_uchastiya ON Sportsmeny.ID = Rezultaty_uchastiya.ID_sportsmena
    LEFT JOIN Sostyazaniya ON Rezultaty_uchastiya.ID_sostyazaniya = Sostyazaniya.ID
    GROUP BY Sportivnye_kluby.ID_sportivnogo_kluba, Sportivnye_kluby.Nazvanie
    ORDER BY Sportsmenov_v_sorevnovaniyah DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetOrganizatoryStatistika` (IN `p_data_nachala` DATE, IN `p_data_konca` DATE)   BEGIN
    SELECT 
        Organizatory_sorevnovaniy.FIO AS Organizator,
        COUNT(Sostyazaniya.ID) AS Kolichestvo_sorevnovaniy,
        MIN(Sostyazaniya.Data_provedeniya) AS Pervoe_sorevnovanie,
        MAX(Sostyazaniya.Data_provedeniya) AS Poslednee_sorevnovanie,
        GROUP_CONCAT(DISTINCT Vidy_sporta.Nazvanie) AS Vidy_sporta,
        GROUP_CONCAT(DISTINCT Sportivnoe_sooruzhenie.Nazvanie) AS Ispolzovannye_sooruzheniya
    FROM Organizatory_sorevnovaniy
    LEFT JOIN Sostyazaniya ON Organizatory_sorevnovaniy.ID_organizatora_sorevnovaniy = Sostyazaniya.ID_Organizatory_sorevnovaniy
    LEFT JOIN Vidy_sporta ON Sostyazaniya.Vid_sporta_ID = Vidy_sporta.ID
    LEFT JOIN Sportivnoe_sooruzhenie ON Sostyazaniya.Sportivnoe_sooruzhenie_ID = Sportivnoe_sooruzhenie.ID
    WHERE 
        (p_data_nachala IS NULL OR Sostyazaniya.Data_provedeniya >= p_data_nachala)
        AND (p_data_konca IS NULL OR Sostyazaniya.Data_provedeniya <= p_data_konca)
    GROUP BY Organizatory_sorevnovaniy.ID_organizatora_sorevnovaniy, Organizatory_sorevnovaniy.FIO
    ORDER BY Kolichestvo_sorevnovaniy DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetPrizerySorevnovaniya` (IN `p_nazvanie_sorevnovaniya` VARCHAR(50))   BEGIN
    SELECT 
        Sportsmeny.FIO AS Sportsmen,
        Sportsmeny.Razryad,
        Sportivnye_kluby.Nazvanie AS Klub,
        Rezultaty_uchastiya.Mesto,
        Rezultaty_uchastiya.Ball,
        Rezultaty_uchastiya.Vremya,
        Nagrazhdenie.Nazvanie_nagrady
    FROM Rezultaty_uchastiya
    JOIN Sportsmeny ON Rezultaty_uchastiya.ID_sportsmena = Sportsmeny.ID
    JOIN Sportivnye_kluby ON Sportsmeny.ID_sportivnogo_kluba = Sportivnye_kluby.ID_sportivnogo_kluba
    JOIN Sostyazaniya ON Rezultaty_uchastiya.ID_sostyazaniya = Sostyazaniya.ID
    LEFT JOIN Nagrazhdenie ON Rezultaty_uchastiya.ID = Nagrazhdenie.ID_rezultata
    WHERE Sostyazaniya.Nazvanie = p_nazvanie_sorevnovaniya
    ORDER BY Rezultaty_uchastiya.Mesto;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSooruzheniyaIDatySorevnovaniy` (IN `p_data_nachala` DATE, IN `p_data_konca` DATE)   BEGIN
    SELECT 
        Sportivnoe_sooruzhenie.Nazvanie AS Sooruzhenie,
        Tip_sooruzheniya.Nazvanie AS Tip_sooruzheniya,
        Sportivnoe_sooruzhenie.Adres,
        GROUP_CONCAT(DISTINCT CONCAT(
            Sostyazaniya.Nazvanie, 
            ' (', Vidy_sporta.Nazvanie, 
            ', ', DATE_FORMAT(Sostyazaniya.Data_provedeniya, '%d.%m.%Y'),
            ')'
        ) ORDER BY Sostyazaniya.Data_provedeniya) AS Spisok_sorevnovaniy,
        COUNT(DISTINCT Sostyazaniya.ID) AS Kolichestvo_sorevnovaniy,
        MIN(Sostyazaniya.Data_provedeniya) AS Pervaya_data,
        MAX(Sostyazaniya.Data_provedeniya) AS Poslednyaya_data
    FROM Sportivnoe_sooruzhenie
    JOIN Tip_sooruzheniya ON Sportivnoe_sooruzhenie.Tip_ID = Tip_sooruzheniya.ID
    LEFT JOIN Sostyazaniya ON Sportivnoe_sooruzhenie.ID = Sostyazaniya.Sportivnoe_sooruzhenie_ID
    LEFT JOIN Vidy_sporta ON Sostyazaniya.Vid_sporta_ID = Vidy_sporta.ID
    WHERE 
        (p_data_nachala IS NULL OR Sostyazaniya.Data_provedeniya >= p_data_nachala)
        AND (p_data_konca IS NULL OR Sostyazaniya.Data_provedeniya <= p_data_konca)
    GROUP BY Sportivnoe_sooruzhenie.ID, Sportivnoe_sooruzhenie.Nazvanie, 
             Tip_sooruzheniya.Nazvanie, Sportivnoe_sooruzhenie.Adres
    ORDER BY Kolichestvo_sorevnovaniy DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSooruzheniyaPoTipu` (IN `p_tip_nazvanie` VARCHAR(50), IN `p_min_vmestimost` INT, IN `p_tip_pokrytiya` VARCHAR(50), IN `p_min_ploshad` FLOAT)   BEGIN
    SELECT 
        Sportivnoe_sooruzhenie.ID,
        Sportivnoe_sooruzhenie.Nazvanie,
        Tip_sooruzheniya.Nazvanie AS Tip_sooruzheniya,
        Sportivnoe_sooruzhenie.Vmestimost,
        Sportivnoe_sooruzhenie.Tip_pokrytiya,
        Sportivnoe_sooruzhenie.Ploshad,
        Sportivnoe_sooruzhenie.Adres
    FROM Sportivnoe_sooruzhenie
    JOIN Tip_sooruzheniya ON Sportivnoe_sooruzhenie.Tip_ID = Tip_sooruzheniya.ID
    WHERE 
        (p_tip_nazvanie IS NULL OR Tip_sooruzheniya.Nazvanie = p_tip_nazvanie)
        AND (p_min_vmestimost IS NULL OR Sportivnoe_sooruzhenie.Vmestimost >= p_min_vmestimost)
        AND (p_tip_pokrytiya IS NULL OR Sportivnoe_sooruzhenie.Tip_pokrytiya = p_tip_pokrytiya)
        AND (p_min_ploshad IS NULL OR Sportivnoe_sooruzhenie.Ploshad >= p_min_ploshad);
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSorevnovaniyaNaSooruzhenii` (IN `p_nazvanie_sooruzheniya` VARCHAR(50), IN `p_vid_sporta` VARCHAR(50))   BEGIN
    SELECT 
        Sostyazaniya.ID,
        Sostyazaniya.Nazvanie,
        Vidy_sporta.Nazvanie AS Vid_sporta,
        Organizatory_sorevnovaniy.FIO AS Organizator,
        Sostyazaniya.Data_provedeniya,
        Sostyazaniya.Vremya_nachala,
        COUNT(Rezultaty_uchastiya.ID) AS Kolichestvo_uchastnikov
    FROM Sostyazaniya
    JOIN Vidy_sporta ON Sostyazaniya.Vid_sporta_ID = Vidy_sporta.ID
    JOIN Sportivnoe_sooruzhenie ON Sostyazaniya.Sportivnoe_sooruzhenie_ID = Sportivnoe_sooruzhenie.ID
    JOIN Organizatory_sorevnovaniy ON Sostyazaniya.ID_Organizatory_sorevnovaniy = Organizatory_sorevnovaniy.ID_organizatora_sorevnovaniy
    LEFT JOIN Rezultaty_uchastiya ON Sostyazaniya.ID = Rezultaty_uchastiya.ID_sostyazaniya
    WHERE 
        Sportivnoe_sooruzhenie.Nazvanie = p_nazvanie_sooruzheniya
        AND (p_vid_sporta IS NULL OR Vidy_sporta.Nazvanie = p_vid_sporta)
    GROUP BY Sostyazaniya.ID, Sostyazaniya.Nazvanie, Vidy_sporta.Nazvanie, 
             Organizatory_sorevnovaniy.FIO, Sostyazaniya.Data_provedeniya, Sostyazaniya.Vremya_nachala
    ORDER BY Sostyazaniya.Data_provedeniya DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSorevnovaniyaZaPeriod` (IN `p_data_nachala` DATE, IN `p_data_konca` DATE, IN `p_organizator_fio` VARCHAR(50))   BEGIN
    SELECT 
        Sostyazaniya.ID,
        Sostyazaniya.Nazvanie,
        Vidy_sporta.Nazvanie AS Vid_sporta,
        Sportivnoe_sooruzhenie.Nazvanie AS Mesto_provedeniya,
        Organizatory_sorevnovaniy.FIO AS Organizator,
        Sostyazaniya.Data_provedeniya,
        Sostyazaniya.Vremya_nachala
    FROM Sostyazaniya
    JOIN Vidy_sporta ON Sostyazaniya.Vid_sporta_ID = Vidy_sporta.ID
    JOIN Sportivnoe_sooruzhenie ON Sostyazaniya.Sportivnoe_sooruzhenie_ID = Sportivnoe_sooruzhenie.ID
    JOIN Organizatory_sorevnovaniy ON Sostyazaniya.ID_Organizatory_sorevnovaniy = Organizatory_sorevnovaniy.ID_organizatora_sorevnovaniy
    WHERE 
        (p_data_nachala IS NULL OR Sostyazaniya.Data_provedeniya >= p_data_nachala)
        AND (p_data_konca IS NULL OR Sostyazaniya.Data_provedeniya <= p_data_konca)
        AND (p_organizator_fio IS NULL OR Organizatory_sorevnovaniy.FIO = p_organizator_fio)
    ORDER BY Sostyazaniya.Data_provedeniya;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSportsmenyBezUchastiya` (IN `p_data_nachala` DATE, IN `p_data_konca` DATE)   BEGIN
    SELECT 
        Sportsmeny.ID,
        Sportsmeny.FIO,
        Sportsmeny.Razryad,
        Sportivnye_kluby.Nazvanie AS Klub,
        GROUP_CONCAT(DISTINCT Vidy_sporta.Nazvanie) AS Vidy_sporta,
        MAX(Trenirovki.Data_nachala) AS Poslednyaya_trenirovka
    FROM Sportsmeny
    JOIN Sportivnye_kluby ON Sportsmeny.ID_sportivnogo_kluba = Sportivnye_kluby.ID_sportivnogo_kluba
    LEFT JOIN Trenirovki ON Sportsmeny.ID = Trenirovki.ID_sportsmena
    LEFT JOIN Vidy_sporta ON Trenirovki.ID_vida_sporta = Vidy_sporta.ID
    WHERE Sportsmeny.ID NOT IN (
        SELECT DISTINCT Rezultaty_uchastiya.ID_sportsmena
        FROM Rezultaty_uchastiya
        JOIN Sostyazaniya ON Rezultaty_uchastiya.ID_sostyazaniya = Sostyazaniya.ID
        WHERE 
            (p_data_nachala IS NULL OR Sostyazaniya.Data_provedeniya >= p_data_nachala)
            AND (p_data_konca IS NULL OR Sostyazaniya.Data_provedeniya <= p_data_konca)
    )
    GROUP BY Sportsmeny.ID, Sportsmeny.FIO, Sportsmeny.Razryad, Sportivnye_kluby.Nazvanie
    ORDER BY Poslednyaya_trenirovka DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSportsmenyPoTreneruIRazryadu` (IN `p_trener_fio` VARCHAR(50), IN `p_min_razryad` VARCHAR(50))   BEGIN
    CREATE TEMPORARY TABLE IF NOT EXISTS RazryadOrder (
        Razryad VARCHAR(50),
        OrderValue INT
    );
    
    INSERT IGNORE INTO RazryadOrder VALUES 
        ('МС', 4),
        ('КМС', 3),
        ('1 разряд', 2),
        ('2 разряд', 1),
        ('3 разряд', 0);
    
    SELECT DISTINCT
        Sportsmeny.ID,
        Sportsmeny.FIO,
        Sportsmeny.Razryad,
        Trenery.FIO AS Trener
    FROM Sportsmeny
    JOIN Trenirovki ON Sportsmeny.ID = Trenirovki.ID_sportsmena
    JOIN Trenery ON Trenirovki.ID_trenera = Trenery.ID
    JOIN RazryadOrder ro ON Sportsmeny.Razryad = ro.Razryad
    WHERE 
        (p_trener_fio IS NULL OR Trenery.FIO = p_trener_fio)
        AND (p_min_razryad IS NULL OR ro.OrderValue >= 
            (SELECT OrderValue FROM RazryadOrder WHERE Razryad = p_min_razryad));
    
    DROP TEMPORARY TABLE IF EXISTS RazryadOrder;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSportsmenyPoTreneruIRazryadu_Fixed` (IN `p_trener_fio` VARCHAR(50), IN `p_min_razryad` VARCHAR(50))   BEGIN
    -- Используем уникальное имя для временной таблицы
    DROP TEMPORARY TABLE IF EXISTS tmp_RazryadOrder;
    
    CREATE TEMPORARY TABLE tmp_RazryadOrder (
        Razryad VARCHAR(50),
        OrderValue INT
    );
    
    INSERT INTO tmp_RazryadOrder VALUES 
        ('МС', 4),
        ('КМС', 3),
        ('1 разряд', 2),
        ('2 разряд', 1),
        ('3 разряд', 0);
    
    SELECT DISTINCT
        Sportsmeny.ID,
        Sportsmeny.FIO,
        Sportsmeny.Razryad,
        Trenery.FIO AS Trener
    FROM Sportsmeny
    JOIN Trenirovki ON Sportsmeny.ID = Trenirovki.ID_sportsmena
    JOIN Trenery ON Trenirovki.ID_trenera = Trenery.ID
    JOIN tmp_RazryadOrder ro ON Sportsmeny.Razryad = ro.Razryad
    WHERE 
        (p_trener_fio IS NULL OR Trenery.FIO = p_trener_fio)
        AND (p_min_razryad IS NULL OR ro.OrderValue >= 
            (SELECT OrderValue FROM tmp_RazryadOrder WHERE Razryad = p_min_razryad));
    
    DROP TEMPORARY TABLE IF EXISTS tmp_RazryadOrder;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSportsmenyPoViduIRazryadu` (IN `p_vid_sporta` VARCHAR(50), IN `p_min_razryad` VARCHAR(50))   BEGIN
    -- Временная таблица для порядка разрядов
    CREATE TEMPORARY TABLE IF NOT EXISTS RazryadOrder (
        Razryad VARCHAR(50),
        OrderValue INT
    );
    
    INSERT IGNORE INTO RazryadOrder VALUES 
        ('МС', 4),
        ('КМС', 3),
        ('1 разряд', 2),
        ('2 разряд', 1),
        ('3 разряд', 0);
    
    SELECT DISTINCT
        Sportsmeny.ID,
        Sportsmeny.FIO,
        Sportsmeny.Razryad,
        Sportsmeny.Pol,
        Sportivnye_kluby.Nazvanie AS Nazvanie_kluba,
        Vidy_sporta.Nazvanie AS Vid_sporta
    FROM Sportsmeny
    JOIN Sportivnye_kluby ON Sportsmeny.ID_sportivnogo_kluba = Sportivnye_kluby.ID_sportivnogo_kluba
    JOIN Trenirovki ON Sportsmeny.ID = Trenirovki.ID_sportsmena
    JOIN Vidy_sporta ON Trenirovki.ID_vida_sporta = Vidy_sporta.ID
    JOIN RazryadOrder ro ON Sportsmeny.Razryad = ro.Razryad
    WHERE 
        (p_vid_sporta IS NULL OR Vidy_sporta.Nazvanie = p_vid_sporta)
        AND (p_min_razryad IS NULL OR ro.OrderValue >= 
            (SELECT OrderValue FROM RazryadOrder WHERE Razryad = p_min_razryad));
    
    DROP TEMPORARY TABLE IF EXISTS RazryadOrder;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetSportsmenySBoletChemOdnymVidomSporta` (IN `p_min_kolichestvo_vidov` INT)   BEGIN
    SELECT 
        Sportsmeny.ID,
        Sportsmeny.FIO,
        Sportsmeny.Razryad,
        Sportivnye_kluby.Nazvanie AS Klub,
        COUNT(DISTINCT Trenirovki.ID_vida_sporta) AS Kolichestvo_vidov_sporta,
        GROUP_CONCAT(DISTINCT Vidy_sporta.Nazvanie) AS Spisok_vidov_sporta
    FROM Sportsmeny
    JOIN Sportivnye_kluby ON Sportsmeny.ID_sportivnogo_kluba = Sportivnye_kluby.ID_sportivnogo_kluba
    JOIN Trenirovki ON Sportsmeny.ID = Trenirovki.ID_sportsmena
    JOIN Vidy_sporta ON Trenirovki.ID_vida_sporta = Vidy_sporta.ID
    GROUP BY Sportsmeny.ID, Sportsmeny.FIO, Sportsmeny.Razryad, Sportivnye_kluby.Nazvanie
    HAVING COUNT(DISTINCT Trenirovki.ID_vida_sporta) > COALESCE(p_min_kolichestvo_vidov, 1)
    ORDER BY Kolichestvo_vidov_sporta DESC;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetTreneryPoViduSporta` (IN `p_vid_sporta` VARCHAR(50))   BEGIN
    SELECT 
        Trenery.ID,
        Trenery.FIO,
        Vidy_sporta.Nazvanie AS Vid_sporta,
        COUNT(DISTINCT Trenirovki.ID_sportsmena) AS Kolichestvo_sportsmenov,
        GROUP_CONCAT(DISTINCT Sportsmeny.FIO) AS Spisok_sportsmenov
    FROM Trenery
    JOIN Vidy_sporta ON Trenery.Vid_sporta_ID = Vidy_sporta.ID
    LEFT JOIN Trenirovki ON Trenery.ID = Trenirovki.ID_trenera
    LEFT JOIN Sportsmeny ON Trenirovki.ID_sportsmena = Sportsmeny.ID
    WHERE Vidy_sporta.Nazvanie = p_vid_sporta
    GROUP BY Trenery.ID, Trenery.FIO, Vidy_sporta.Nazvanie;
END$$

CREATE DEFINER=`root`@`%` PROCEDURE `GetTrenerySportsmena` (IN `p_sportsmen_fio` VARCHAR(50))   BEGIN
    SELECT DISTINCT
        Trenery.ID,
        Trenery.FIO AS Trener,
        Vidy_sporta.Nazvanie AS Vid_sporta,
        Trenirovki.Data_nachala AS Data_nachala_trenirovok
    FROM Trenery
    JOIN Trenirovki ON Trenery.ID = Trenirovki.ID_trenera
    JOIN Sportsmeny ON Trenirovki.ID_sportsmena = Sportsmeny.ID
    JOIN Vidy_sporta ON Trenirovki.ID_vida_sporta = Vidy_sporta.ID
    WHERE Sportsmeny.FIO = p_sportsmen_fio
    ORDER BY Trenirovki.Data_nachala;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `Nagrazhdenie`
--

CREATE TABLE `Nagrazhdenie` (
  `ID` int NOT NULL,
  `ID_rezultata` int DEFAULT NULL,
  `Nazvanie_nagrady` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Nagrazhdenie`
--

INSERT INTO `Nagrazhdenie` (`ID`, `ID_rezultata`, `Nazvanie_nagrady`) VALUES
(1, 1, 'Золотая медаль'),
(2, 2, 'Серебряная медаль'),
(3, 3, 'Кубок победителя'),
(4, 101, 'Золотая медаль'),
(5, 102, 'Золотая медаль'),
(6, 103, 'Золотая медаль'),
(7, 104, 'Золотая медаль'),
(8, 105, 'Диплом участника');

-- --------------------------------------------------------

--
-- Структура таблицы `Organizatory_sorevnovaniy`
--

CREATE TABLE `Organizatory_sorevnovaniy` (
  `ID_organizatora_sorevnovaniy` int NOT NULL,
  `FIO` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Organizatory_sorevnovaniy`
--

INSERT INTO `Organizatory_sorevnovaniy` (`ID_organizatora_sorevnovaniy`, `FIO`) VALUES
(1, 'Гордеев Олег Николаевич'),
(2, 'Тихонова Анна Михайловна'),
(3, 'Петров Петр Петрович'),
(4, 'Петров Петр Петрович');

-- --------------------------------------------------------

--
-- Структура таблицы `Rezultaty_uchastiya`
--

CREATE TABLE `Rezultaty_uchastiya` (
  `ID` int NOT NULL,
  `ID_sostyazaniya` int DEFAULT NULL,
  `ID_sportsmena` int DEFAULT NULL,
  `Mesto` int DEFAULT NULL,
  `Ball` float DEFAULT NULL,
  `Vremya` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Rezultaty_uchastiya`
--

INSERT INTO `Rezultaty_uchastiya` (`ID`, `ID_sostyazaniya`, `ID_sportsmena`, `Mesto`, `Ball`, `Vremya`) VALUES
(1, 1, 1, 1, 95.5, '02:15:30'),
(2, 1, 2, 2, 88, '02:20:15'),
(3, 2, 3, 1, 98, '01:45:20'),
(100, 100, 1, NULL, 90.5, '02:30:00'),
(101, 1, 1, 1, 98.5, NULL),
(102, 1, 1, 1, 95.5, NULL),
(103, 1, 1, 1, 95.5, NULL),
(104, NULL, NULL, 1, 95.5, '01:30:25'),
(105, NULL, NULL, 4, 85, '01:35:10');

--
-- Триггеры `Rezultaty_uchastiya`
--
DELIMITER $$
CREATE TRIGGER `auto_nagrazhdenie` AFTER INSERT ON `Rezultaty_uchastiya` FOR EACH ROW BEGIN
    -- Автоматическое награждение в зависимости от места
    IF NEW.Mesto = 1 THEN
        INSERT INTO Nagrazhdenie (ID_rezultata, Nazvanie_nagrady)
        VALUES (NEW.ID, 'Золотая медаль');
    ELSEIF NEW.Mesto = 2 THEN
        INSERT INTO Nagrazhdenie (ID_rezultata, Nazvanie_nagrady)
        VALUES (NEW.ID, 'Серебряная медаль');
    ELSEIF NEW.Mesto = 3 THEN
        INSERT INTO Nagrazhdenie (ID_rezultata, Nazvanie_nagrady)
        VALUES (NEW.ID, 'Бронзовая медаль');
    ELSEIF NEW.Mesto BETWEEN 4 AND 10 THEN
        INSERT INTO Nagrazhdenie (ID_rezultata, Nazvanie_nagrady)
        VALUES (NEW.ID, 'Диплом участника');
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `auto_povyshenie_razryada` AFTER INSERT ON `Rezultaty_uchastiya` FOR EACH ROW BEGIN
    DECLARE current_razryad VARCHAR(50);
    
    -- Получаем текущий разряд спортсмена
    SELECT Razryad INTO current_razryad 
    FROM Sportsmeny 
    WHERE ID = NEW.ID_sportsmena;
    
    -- Если спортсмен занял 1 место и его разряд ниже МС
    IF NEW.Mesto = 1 AND current_razryad != 'МС' THEN
        UPDATE Sportsmeny 
        SET Razryad = 'МС' 
        WHERE ID = NEW.ID_sportsmena;
    -- Если спортсмен занял 2-3 место и его разряд ниже КМС
    ELSEIF NEW.Mesto IN (2, 3) AND current_razryad NOT IN ('МС', 'КМС') THEN
        UPDATE Sportsmeny 
        SET Razryad = 'КМС' 
        WHERE ID = NEW.ID_sportsmena;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `role_sportsmen1_info`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `role_sportsmen1_info` (
`FIO` varchar(50)
,`ID` int
,`Klub` varchar(50)
,`Pol` enum('muzhskoy','zhenskiy')
,`Razryad` varchar(50)
,`Vidy_sporta` text
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `role_sportsmen1_rezultaty`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `role_sportsmen1_rezultaty` (
`Ball` float
,`Data_provedeniya` date
,`Mesto` int
,`Mesto_provedeniya` varchar(50)
,`Nazvanie_nagrady` varchar(50)
,`Sorevnovanie` varchar(50)
,`Vid_sporta` varchar(50)
,`Vremya` time
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `role_trener1_sportsmeny`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `role_trener1_sportsmeny` (
`FIO` varchar(50)
,`ID` int
,`Klub` varchar(50)
,`Pol` enum('muzhskoy','zhenskiy')
,`Poslednyaya_trenirovka` date
,`Razryad` varchar(50)
,`Vid_sporta` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `role_trener1_trenirovki`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `role_trener1_trenirovki` (
`Data_nachala` date
,`ID_trenirovki` int
,`Sportsmen` varchar(50)
,`Vid_sporta` varchar(50)
,`Vremya_nachala` time
);

-- --------------------------------------------------------

--
-- Структура таблицы `Sostyazaniya`
--

CREATE TABLE `Sostyazaniya` (
  `ID` int NOT NULL,
  `Nazvanie` varchar(50) NOT NULL,
  `Vid_sporta_ID` int DEFAULT NULL,
  `Sportivnoe_sooruzhenie_ID` int DEFAULT NULL,
  `ID_Organizatory_sorevnovaniy` int DEFAULT NULL,
  `Data_provedeniya` date DEFAULT NULL,
  `Vremya_nachala` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Sostyazaniya`
--

INSERT INTO `Sostyazaniya` (`ID`, `Nazvanie`, `Vid_sporta_ID`, `Sportivnoe_sooruzhenie_ID`, `ID_Organizatory_sorevnovaniy`, `Data_provedeniya`, `Vremya_nachala`) VALUES
(1, 'Чемпионат города по футболу', 1, 1, 1, '2024-05-15', '15:00:00'),
(2, 'Теннисный турнир \"Весна-2024\"', 2, 2, 2, '2024-04-20', '11:00:00'),
(3, 'Кубок города по баскетболу', 3, 3, 1, '2024-09-15', '18:00:00'),
(100, 'Тестовое соревнование', 1, 1, 1, '2024-12-01', '10:00:00'),
(101, 'Чемпионат города по футболу', NULL, NULL, NULL, '2024-02-01', '15:00:00');

-- --------------------------------------------------------

--
-- Структура таблицы `Sostyazaniya_backup`
--

CREATE TABLE `Sostyazaniya_backup` (
  `ID` int DEFAULT NULL,
  `Nazvanie` varchar(50) DEFAULT NULL,
  `Vid_sporta_ID` int DEFAULT NULL,
  `Sportivnoe_sooruzhenie_ID` int DEFAULT NULL,
  `ID_Organizatory_sorevnovaniy` int DEFAULT NULL,
  `Data_provedeniya` date DEFAULT NULL,
  `Vremya_nachala` time DEFAULT NULL,
  `Data_udaleniya` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Структура таблицы `Sportivnoe_sooruzhenie`
--

CREATE TABLE `Sportivnoe_sooruzhenie` (
  `ID` int NOT NULL,
  `Nazvanie` varchar(50) NOT NULL,
  `Tip_ID` int DEFAULT NULL,
  `Vmestimost` int DEFAULT NULL,
  `Tip_pokrytiya` varchar(50) DEFAULT NULL,
  `Ploshad` float DEFAULT NULL,
  `Adres` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Sportivnoe_sooruzhenie`
--

INSERT INTO `Sportivnoe_sooruzhenie` (`ID`, `Nazvanie`, `Tip_ID`, `Vmestimost`, `Tip_pokrytiya`, `Ploshad`, `Adres`) VALUES
(1, 'Центральный стадион', 1, 10000, NULL, NULL, 'ул. Спортивная, 1'),
(2, 'Теннисный корт №1', 2, NULL, 'Хард', NULL, 'ул. Тенисная, 5'),
(3, 'Баскетбольный зал', 3, NULL, NULL, 1200.5, 'ул. Баскетбольная, 10'),
(4, 'Легкоатлетический манеж', 4, NULL, NULL, 2000, 'ул. Легкоатлетическая, 3'),
(10, 'MPT', 1, 3000, 'газон', 10000, 'Москва, нежинская 7'),
(100, 'Тестовый стадион', 1, -100, NULL, NULL, 'ул. Тестовая, 1'),
(101, 'Центральный стадион', NULL, 5000, NULL, NULL, 'ул. Спортивная, 1'),
(102, 'Тестовый стадион', NULL, NULL, NULL, NULL, 'ул. Тестовая, 1');

--
-- Триггеры `Sportivnoe_sooruzhenie`
--
DELIMITER $$
CREATE TRIGGER `check_sooruzhenie_insert` BEFORE INSERT ON `Sportivnoe_sooruzhenie` FOR EACH ROW BEGIN
    DECLARE tip_nazv VARCHAR(50);
    
    -- Получаем название типа сооружения
    SELECT Nazvanie INTO tip_nazv 
    FROM Tip_sooruzheniya 
    WHERE ID = NEW.Tip_ID;
    
    -- Проверяем в зависимости от типа
    IF tip_nazv = 'Стадион' AND NEW.Vmestimost IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Для стадиона обязательна вместимость!';
    ELSEIF tip_nazv = 'Корт' AND NEW.Tip_pokrytiya IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Для корта обязателен тип покрытия!';
    ELSEIF tip_nazv = 'Спортивный зал' AND NEW.Ploshad IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Для спортивного зала обязательна площадь!';
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `check_sooruzhenie_update` BEFORE UPDATE ON `Sportivnoe_sooruzhenie` FOR EACH ROW BEGIN
    DECLARE tip_nazv VARCHAR(50);
    
    SELECT Nazvanie INTO tip_nazv 
    FROM Tip_sooruzheniya 
    WHERE ID = NEW.Tip_ID;
    
    IF tip_nazv = 'Стадион' AND NEW.Vmestimost IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Для стадиона обязательна вместимость!';
    ELSEIF tip_nazv = 'Корт' AND NEW.Tip_pokrytiya IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Для корта обязателен тип покрытия!';
    ELSEIF tip_nazv = 'Спортивный зал' AND NEW.Ploshad IS NULL THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Для спортивного зала обязательна площадь!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `Sportivnye_kluby`
--

CREATE TABLE `Sportivnye_kluby` (
  `ID_sportivnogo_kluba` int NOT NULL,
  `Nazvanie` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Sportivnye_kluby`
--

INSERT INTO `Sportivnye_kluby` (`ID_sportivnogo_kluba`, `Nazvanie`) VALUES
(1, 'Спартак'),
(2, 'Динамо'),
(3, 'ЦСКА'),
(4, 'Тестовый клуб');

-- --------------------------------------------------------

--
-- Структура таблицы `Sportsmeny`
--

CREATE TABLE `Sportsmeny` (
  `ID` int NOT NULL,
  `FIO` varchar(50) NOT NULL,
  `Razryad` varchar(50) DEFAULT NULL,
  `Pol` enum('muzhskoy','zhenskiy') DEFAULT NULL,
  `ID_sportivnogo_kluba` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Sportsmeny`
--

INSERT INTO `Sportsmeny` (`ID`, `FIO`, `Razryad`, `Pol`, `ID_sportivnogo_kluba`) VALUES
(1, 'Иванов Иван Иванович (изменено)', 'МС', 'muzhskoy', 1),
(2, 'Петров Петр Петрович', '1 разряд', 'muzhskoy', 2),
(3, 'Сидоров Алексей Владимирович', 'МС', 'muzhskoy', 1),
(4, 'Новиков Сергей Васильевич', '1 разряд', 'muzhskoy', 2),
(5, 'Смирнова Анна Игоревна', 'МС', 'zhenskiy', 2),
(6, 'Васильев Денис Сергеевич', 'КМС', 'muzhskoy', 3),
(7, 'Ковалева Мария Викторовна', '1 разряд', 'zhenskiy', 1),
(8, 'Николаев Александр Петрович', '2 разряд', 'muzhskoy', 2),
(9, 'Федорова Екатерина Андреевна', '3 разряд', 'zhenskiy', 3),
(10, 'Тестовый Спортсмен', '3 разряд', 'muzhskoy', 1),
(11, 'Иванов Иван Иванович', '1 разряд', 'muzhskoy', 4);

--
-- Триггеры `Sportsmeny`
--
DELIMITER $$
CREATE TRIGGER `log_sportsmen_update` AFTER UPDATE ON `Sportsmeny` FOR EACH ROW BEGIN
    -- Записываем изменения в лог
    INSERT INTO Sportsmeny_log (ID_sportsmena, Staroe_FIO, Novoe_FIO, Staryy_razryad, Novyy_razryad, Deystvie)
    VALUES (OLD.ID, OLD.FIO, NEW.FIO, OLD.Razryad, NEW.Razryad, 'UPDATE');
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `Sportsmeny_log`
--

CREATE TABLE `Sportsmeny_log` (
  `ID_log` int NOT NULL,
  `ID_sportsmena` int DEFAULT NULL,
  `Staroe_FIO` varchar(50) DEFAULT NULL,
  `Novoe_FIO` varchar(50) DEFAULT NULL,
  `Staryy_razryad` varchar(50) DEFAULT NULL,
  `Novyy_razryad` varchar(50) DEFAULT NULL,
  `Data_izmeneniya` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `Deystvie` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Sportsmeny_log`
--

INSERT INTO `Sportsmeny_log` (`ID_log`, `ID_sportsmena`, `Staroe_FIO`, `Novoe_FIO`, `Staryy_razryad`, `Novyy_razryad`, `Data_izmeneniya`, `Deystvie`) VALUES
(1, 1, 'Иванов Иван Иванович', 'Иванов Иван Иванович', 'КМС', 'МС', '2025-12-18 22:58:36', 'UPDATE'),
(2, 1, 'Иванов Иван Иванович', 'Иванов Иван Иванович (изменено)', 'МС', 'КМС', '2025-12-18 23:09:26', 'UPDATE'),
(3, 1, 'Иванов Иван Иванович (изменено)', 'Иванов Иван Иванович (изменено)', 'КМС', 'МС', '2025-12-18 23:18:23', 'UPDATE');

-- --------------------------------------------------------

--
-- Структура таблицы `Tip_sooruzheniya`
--

CREATE TABLE `Tip_sooruzheniya` (
  `ID` int NOT NULL,
  `Nazvanie` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Tip_sooruzheniya`
--

INSERT INTO `Tip_sooruzheniya` (`ID`, `Nazvanie`) VALUES
(2, 'Корт'),
(4, 'Манеж'),
(3, 'Спортивный зал'),
(1, 'Стадион');

-- --------------------------------------------------------

--
-- Структура таблицы `Trenery`
--

CREATE TABLE `Trenery` (
  `ID` int NOT NULL,
  `FIO` varchar(50) NOT NULL,
  `Vid_sporta_ID` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Trenery`
--

INSERT INTO `Trenery` (`ID`, `FIO`, `Vid_sporta_ID`) VALUES
(1, 'Смирнов Александр Сергеевич', 1),
(2, 'Кузнецова Мария Ивановна', 2),
(3, 'Васильев Дмитрий Петрович', 3),
(4, 'Петров Сергей Владимирович', 1),
(5, 'Иванова Ольга Николаевна', 2),
(6, 'Сидорова Елена Петровна', 3),
(7, 'Козлов Андрей Михайлович', 4),
(8, 'Смирнов Александр Сергеевич', NULL);

-- --------------------------------------------------------

--
-- Структура таблицы `Trenirovki`
--

CREATE TABLE `Trenirovki` (
  `ID_trenirovki` int NOT NULL,
  `ID_trenera` int DEFAULT NULL,
  `ID_sportsmena` int DEFAULT NULL,
  `ID_vida_sporta` int DEFAULT NULL,
  `Data_nachala` date DEFAULT NULL,
  `Vremya_nachala` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Trenirovki`
--

INSERT INTO `Trenirovki` (`ID_trenirovki`, `ID_trenera`, `ID_sportsmena`, `ID_vida_sporta`, `Data_nachala`, `Vremya_nachala`) VALUES
(1, 1, 1, 1, '2024-01-15', '10:00:00'),
(2, 2, 2, 2, '2024-02-20', '14:30:00'),
(3, 3, 3, 3, '2024-03-10', '16:00:00'),
(4, 1, 2, 1, '2024-03-01', '09:00:00'),
(5, 2, 3, 2, '2024-03-05', '14:00:00'),
(6, 3, 4, 3, '2024-03-10', '16:30:00'),
(7, 4, 1, 1, '2024-03-15', '10:00:00'),
(8, 5, 2, 2, '2024-03-20', '15:00:00'),
(9, 6, 3, 3, '2024-03-25', '17:00:00'),
(10, 7, 4, 4, '2024-04-01', '11:00:00'),
(11, 1, 5, 1, '2024-04-05', '09:30:00'),
(12, 2, 6, 2, '2024-04-10', '14:30:00'),
(13, 3, 7, 3, '2024-04-15', '16:00:00'),
(14, 4, 8, 1, '2024-04-20', '10:30:00'),
(15, 5, 9, 2, '2024-04-25', '15:30:00'),
(16, 1, 5, 1, '2024-05-01', '09:00:00'),
(17, 2, 6, 2, '2024-05-05', '14:00:00'),
(18, 4, 8, 1, '2024-05-10', '10:00:00'),
(19, 5, 9, 2, '2024-05-15', '15:00:00'),
(20, NULL, NULL, 2, '2024-01-15', '10:00:00');

--
-- Триггеры `Trenirovki`
--
DELIMITER $$
CREATE TRIGGER `check_trener_vid_sporta` BEFORE INSERT ON `Trenirovki` FOR EACH ROW BEGIN
    DECLARE vid_trenera INT;
    
    -- Получаем вид спорта тренера
    SELECT Vid_sporta_ID INTO vid_trenera 
    FROM Trenery 
    WHERE ID = NEW.ID_trenera;
    
    -- Проверяем, совпадает ли вид спорта
    IF vid_trenera != NEW.ID_vida_sporta THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Тренер не тренирует данный вид спорта!';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Структура таблицы `Vidy_sporta`
--

CREATE TABLE `Vidy_sporta` (
  `ID` int NOT NULL,
  `Nazvanie` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Дамп данных таблицы `Vidy_sporta`
--

INSERT INTO `Vidy_sporta` (`ID`, `Nazvanie`) VALUES
(1, 'Футбол'),
(2, 'Теннис'),
(3, 'Баскетбол'),
(4, 'Легкая атлетика'),
(5, 'Футбол'),
(6, 'Теннис');

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_kluby_aktivnost`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_kluby_aktivnost` (
`Klub` varchar(50)
,`Kolichestvo_uchastnikov` bigint
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_organizatory_statistika`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_organizatory_statistika` (
`Kolichestvo_sorevnovaniy` bigint
,`Organizator` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_prizery_sorevnovaniya`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_prizery_sorevnovaniya` (
`Ball` float
,`Mesto` int
,`Nazvanie_nagrady` varchar(50)
,`Sorevnovanie` varchar(50)
,`Sportsmen` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sooruzheniya_i_daty`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sooruzheniya_i_daty` (
`Data_provedeniya` date
,`Sooruzhenie` varchar(50)
,`Sorevnovanie` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sooruzheniya_tipa`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sooruzheniya_tipa` (
`Adres` varchar(100)
,`ID` int
,`Nazvanie` varchar(50)
,`Ploshad` float
,`Tip_ID` int
,`Tip_nazvanie` varchar(50)
,`Tip_pokrytiya` varchar(50)
,`Vmestimost` int
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sorevnovaniya_na_sooruzhenii`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sorevnovaniya_na_sooruzhenii` (
`Data_provedeniya` date
,`ID` int
,`ID_Organizatory_sorevnovaniy` int
,`Nazvanie` varchar(50)
,`Sooruzhenie` varchar(50)
,`Sportivnoe_sooruzhenie_ID` int
,`Vid_sporta` varchar(50)
,`Vid_sporta_ID` int
,`Vremya_nachala` time
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sorevnovaniya_period`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sorevnovaniya_period` (
`Data_provedeniya` date
,`ID` int
,`ID_Organizatory_sorevnovaniy` int
,`Nazvanie` varchar(50)
,`Organizator` varchar(50)
,`Sportivnoe_sooruzhenie_ID` int
,`Vid_sporta` varchar(50)
,`Vid_sporta_ID` int
,`Vremya_nachala` time
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sportsmeny_bez_uchastiya`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sportsmeny_bez_uchastiya` (
`FIO` varchar(50)
,`ID` int
,`ID_sportivnogo_kluba` int
,`Pol` enum('muzhskoy','zhenskiy')
,`Razryad` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sportsmeny_mnogo_vidov`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sportsmeny_mnogo_vidov` (
`FIO` varchar(50)
,`Kolichestvo_vidov` bigint
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sportsmeny_trener`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sportsmeny_trener` (
`FIO` varchar(50)
,`ID` int
,`ID_sportivnogo_kluba` int
,`Pol` enum('muzhskoy','zhenskiy')
,`Razryad` varchar(50)
,`Trener_FIO` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_sportsmeny_vid_razryad`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_sportsmeny_vid_razryad` (
`FIO` varchar(50)
,`ID` int
,`ID_sportivnogo_kluba` int
,`Pol` enum('muzhskoy','zhenskiy')
,`Razryad` varchar(50)
,`Vid_sporta` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_trenery_po_vidu_sporta`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_trenery_po_vidu_sporta` (
`Trener` varchar(50)
,`Vid_sporta` varchar(50)
);

-- --------------------------------------------------------

--
-- Дублирующая структура для представления `view_trenery_sportsmena`
-- (См. Ниже фактическое представление)
--
CREATE TABLE `view_trenery_sportsmena` (
`Sportsmen` varchar(50)
,`Trener` varchar(50)
,`Vid_sporta` varchar(50)
);

-- --------------------------------------------------------

--
-- Структура для представления `role_sportsmen1_info`
--
DROP TABLE IF EXISTS `role_sportsmen1_info`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `role_sportsmen1_info`  AS SELECT `s`.`ID` AS `ID`, `s`.`FIO` AS `FIO`, `s`.`Razryad` AS `Razryad`, `s`.`Pol` AS `Pol`, `sk`.`Nazvanie` AS `Klub`, group_concat(distinct `vs`.`Nazvanie` separator ',') AS `Vidy_sporta` FROM (((`sportsmeny` `s` join `sportivnye_kluby` `sk` on((`s`.`ID_sportivnogo_kluba` = `sk`.`ID_sportivnogo_kluba`))) left join `trenirovki` `t` on((`s`.`ID` = `t`.`ID_sportsmena`))) left join `vidy_sporta` `vs` on((`t`.`ID_vida_sporta` = `vs`.`ID`))) WHERE (`s`.`ID` = 1) GROUP BY `s`.`ID`, `s`.`FIO`, `s`.`Razryad`, `s`.`Pol`, `sk`.`Nazvanie``Nazvanie`  ;

-- --------------------------------------------------------

--
-- Структура для представления `role_sportsmen1_rezultaty`
--
DROP TABLE IF EXISTS `role_sportsmen1_rezultaty`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `role_sportsmen1_rezultaty`  AS SELECT `r`.`Mesto` AS `Mesto`, `r`.`Ball` AS `Ball`, `r`.`Vremya` AS `Vremya`, `s`.`Nazvanie` AS `Sorevnovanie`, `vs`.`Nazvanie` AS `Vid_sporta`, `n`.`Nazvanie_nagrady` AS `Nazvanie_nagrady`, `s`.`Data_provedeniya` AS `Data_provedeniya`, `ss`.`Nazvanie` AS `Mesto_provedeniya` FROM ((((`rezultaty_uchastiya` `r` join `sostyazaniya` `s` on((`r`.`ID_sostyazaniya` = `s`.`ID`))) join `vidy_sporta` `vs` on((`s`.`Vid_sporta_ID` = `vs`.`ID`))) left join `nagrazhdenie` `n` on((`r`.`ID` = `n`.`ID_rezultata`))) left join `sportivnoe_sooruzhenie` `ss` on((`s`.`Sportivnoe_sooruzhenie_ID` = `ss`.`ID`))) WHERE (`r`.`ID_sportsmena` = 1)  ;

-- --------------------------------------------------------

--
-- Структура для представления `role_trener1_sportsmeny`
--
DROP TABLE IF EXISTS `role_trener1_sportsmeny`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `role_trener1_sportsmeny`  AS SELECT `s`.`ID` AS `ID`, `s`.`FIO` AS `FIO`, `s`.`Razryad` AS `Razryad`, `s`.`Pol` AS `Pol`, `sk`.`Nazvanie` AS `Klub`, `vs`.`Nazvanie` AS `Vid_sporta`, max(`t`.`Data_nachala`) AS `Poslednyaya_trenirovka` FROM (((`sportsmeny` `s` join `sportivnye_kluby` `sk` on((`s`.`ID_sportivnogo_kluba` = `sk`.`ID_sportivnogo_kluba`))) join `trenirovki` `t` on((`s`.`ID` = `t`.`ID_sportsmena`))) join `vidy_sporta` `vs` on((`t`.`ID_vida_sporta` = `vs`.`ID`))) WHERE (`t`.`ID_trenera` = 1) GROUP BY `s`.`ID`, `s`.`FIO`, `s`.`Razryad`, `s`.`Pol`, `sk`.`Nazvanie`, `vs`.`Nazvanie``Nazvanie`  ;

-- --------------------------------------------------------

--
-- Структура для представления `role_trener1_trenirovki`
--
DROP TABLE IF EXISTS `role_trener1_trenirovki`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `role_trener1_trenirovki`  AS SELECT `t`.`ID_trenirovki` AS `ID_trenirovki`, `t`.`Data_nachala` AS `Data_nachala`, `t`.`Vremya_nachala` AS `Vremya_nachala`, `s`.`FIO` AS `Sportsmen`, `vs`.`Nazvanie` AS `Vid_sporta` FROM ((`trenirovki` `t` join `sportsmeny` `s` on((`t`.`ID_sportsmena` = `s`.`ID`))) join `vidy_sporta` `vs` on((`t`.`ID_vida_sporta` = `vs`.`ID`))) WHERE (`t`.`ID_trenera` = 1)  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_kluby_aktivnost`
--
DROP TABLE IF EXISTS `view_kluby_aktivnost`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_kluby_aktivnost`  AS SELECT `sk`.`Nazvanie` AS `Klub`, count(distinct `ru`.`ID_sportsmena`) AS `Kolichestvo_uchastnikov` FROM ((`sportivnye_kluby` `sk` join `sportsmeny` `s` on((`sk`.`ID_sportivnogo_kluba` = `s`.`ID_sportivnogo_kluba`))) join `rezultaty_uchastiya` `ru` on((`s`.`ID` = `ru`.`ID_sportsmena`))) GROUP BY `sk`.`ID_sportivnogo_kluba``ID_sportivnogo_kluba`  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_organizatory_statistika`
--
DROP TABLE IF EXISTS `view_organizatory_statistika`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_organizatory_statistika`  AS SELECT `o`.`FIO` AS `Organizator`, count(`s`.`ID`) AS `Kolichestvo_sorevnovaniy` FROM (`organizatory_sorevnovaniy` `o` left join `sostyazaniya` `s` on((`o`.`ID_organizatora_sorevnovaniy` = `s`.`ID_Organizatory_sorevnovaniy`))) GROUP BY `o`.`ID_organizatora_sorevnovaniy``ID_organizatora_sorevnovaniy`  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_prizery_sorevnovaniya`
--
DROP TABLE IF EXISTS `view_prizery_sorevnovaniya`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_prizery_sorevnovaniya`  AS SELECT `s`.`Nazvanie` AS `Sorevnovanie`, `sp`.`FIO` AS `Sportsmen`, `ru`.`Mesto` AS `Mesto`, `ru`.`Ball` AS `Ball`, `n`.`Nazvanie_nagrady` AS `Nazvanie_nagrady` FROM (((`rezultaty_uchastiya` `ru` join `sostyazaniya` `s` on((`ru`.`ID_sostyazaniya` = `s`.`ID`))) join `sportsmeny` `sp` on((`ru`.`ID_sportsmena` = `sp`.`ID`))) left join `nagrazhdenie` `n` on((`ru`.`ID` = `n`.`ID_rezultata`))) WHERE (`ru`.`Mesto` in (1,2,3))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sooruzheniya_i_daty`
--
DROP TABLE IF EXISTS `view_sooruzheniya_i_daty`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sooruzheniya_i_daty`  AS SELECT `ss`.`Nazvanie` AS `Sooruzhenie`, `s`.`Nazvanie` AS `Sorevnovanie`, `s`.`Data_provedeniya` AS `Data_provedeniya` FROM (`sportivnoe_sooruzhenie` `ss` join `sostyazaniya` `s` on((`ss`.`ID` = `s`.`Sportivnoe_sooruzhenie_ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sooruzheniya_tipa`
--
DROP TABLE IF EXISTS `view_sooruzheniya_tipa`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sooruzheniya_tipa`  AS SELECT `ss`.`ID` AS `ID`, `ss`.`Nazvanie` AS `Nazvanie`, `ss`.`Tip_ID` AS `Tip_ID`, `ss`.`Vmestimost` AS `Vmestimost`, `ss`.`Tip_pokrytiya` AS `Tip_pokrytiya`, `ss`.`Ploshad` AS `Ploshad`, `ss`.`Adres` AS `Adres`, `ts`.`Nazvanie` AS `Tip_nazvanie` FROM (`sportivnoe_sooruzhenie` `ss` join `tip_sooruzheniya` `ts` on((`ss`.`Tip_ID` = `ts`.`ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sorevnovaniya_na_sooruzhenii`
--
DROP TABLE IF EXISTS `view_sorevnovaniya_na_sooruzhenii`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sorevnovaniya_na_sooruzhenii`  AS SELECT `ss`.`Nazvanie` AS `Sooruzhenie`, `s`.`ID` AS `ID`, `s`.`Nazvanie` AS `Nazvanie`, `s`.`Vid_sporta_ID` AS `Vid_sporta_ID`, `s`.`Sportivnoe_sooruzhenie_ID` AS `Sportivnoe_sooruzhenie_ID`, `s`.`ID_Organizatory_sorevnovaniy` AS `ID_Organizatory_sorevnovaniy`, `s`.`Data_provedeniya` AS `Data_provedeniya`, `s`.`Vremya_nachala` AS `Vremya_nachala`, `vs`.`Nazvanie` AS `Vid_sporta` FROM ((`sostyazaniya` `s` join `sportivnoe_sooruzhenie` `ss` on((`s`.`Sportivnoe_sooruzhenie_ID` = `ss`.`ID`))) join `vidy_sporta` `vs` on((`s`.`Vid_sporta_ID` = `vs`.`ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sorevnovaniya_period`
--
DROP TABLE IF EXISTS `view_sorevnovaniya_period`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sorevnovaniya_period`  AS SELECT `s`.`ID` AS `ID`, `s`.`Nazvanie` AS `Nazvanie`, `s`.`Vid_sporta_ID` AS `Vid_sporta_ID`, `s`.`Sportivnoe_sooruzhenie_ID` AS `Sportivnoe_sooruzhenie_ID`, `s`.`ID_Organizatory_sorevnovaniy` AS `ID_Organizatory_sorevnovaniy`, `s`.`Data_provedeniya` AS `Data_provedeniya`, `s`.`Vremya_nachala` AS `Vremya_nachala`, `o`.`FIO` AS `Organizator`, `vs`.`Nazvanie` AS `Vid_sporta` FROM ((`sostyazaniya` `s` join `organizatory_sorevnovaniy` `o` on((`s`.`ID_Organizatory_sorevnovaniy` = `o`.`ID_organizatora_sorevnovaniy`))) join `vidy_sporta` `vs` on((`s`.`Vid_sporta_ID` = `vs`.`ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sportsmeny_bez_uchastiya`
--
DROP TABLE IF EXISTS `view_sportsmeny_bez_uchastiya`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sportsmeny_bez_uchastiya`  AS SELECT `s`.`ID` AS `ID`, `s`.`FIO` AS `FIO`, `s`.`Razryad` AS `Razryad`, `s`.`Pol` AS `Pol`, `s`.`ID_sportivnogo_kluba` AS `ID_sportivnogo_kluba` FROM (`sportsmeny` `s` left join `rezultaty_uchastiya` `ru` on((`s`.`ID` = `ru`.`ID_sportsmena`))) WHERE (`ru`.`ID` is null)  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sportsmeny_mnogo_vidov`
--
DROP TABLE IF EXISTS `view_sportsmeny_mnogo_vidov`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sportsmeny_mnogo_vidov`  AS SELECT `s`.`FIO` AS `FIO`, count(distinct `t`.`ID_vida_sporta`) AS `Kolichestvo_vidov` FROM (`sportsmeny` `s` join `trenirovki` `t` on((`s`.`ID` = `t`.`ID_sportsmena`))) GROUP BY `s`.`ID` HAVING (`Kolichestvo_vidov` > 1)  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sportsmeny_trener`
--
DROP TABLE IF EXISTS `view_sportsmeny_trener`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sportsmeny_trener`  AS SELECT `s`.`ID` AS `ID`, `s`.`FIO` AS `FIO`, `s`.`Razryad` AS `Razryad`, `s`.`Pol` AS `Pol`, `s`.`ID_sportivnogo_kluba` AS `ID_sportivnogo_kluba`, `tr`.`FIO` AS `Trener_FIO` FROM ((`sportsmeny` `s` join `trenirovki` `t` on((`s`.`ID` = `t`.`ID_sportsmena`))) join `trenery` `tr` on((`t`.`ID_trenera` = `tr`.`ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_sportsmeny_vid_razryad`
--
DROP TABLE IF EXISTS `view_sportsmeny_vid_razryad`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_sportsmeny_vid_razryad`  AS SELECT `s`.`ID` AS `ID`, `s`.`FIO` AS `FIO`, `s`.`Razryad` AS `Razryad`, `s`.`Pol` AS `Pol`, `s`.`ID_sportivnogo_kluba` AS `ID_sportivnogo_kluba`, `vs`.`Nazvanie` AS `Vid_sporta` FROM ((`sportsmeny` `s` join `trenirovki` `t` on((`s`.`ID` = `t`.`ID_sportsmena`))) join `vidy_sporta` `vs` on((`t`.`ID_vida_sporta` = `vs`.`ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_trenery_po_vidu_sporta`
--
DROP TABLE IF EXISTS `view_trenery_po_vidu_sporta`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_trenery_po_vidu_sporta`  AS SELECT `tr`.`FIO` AS `Trener`, `vs`.`Nazvanie` AS `Vid_sporta` FROM (`trenery` `tr` join `vidy_sporta` `vs` on((`tr`.`Vid_sporta_ID` = `vs`.`ID`)))  ;

-- --------------------------------------------------------

--
-- Структура для представления `view_trenery_sportsmena`
--
DROP TABLE IF EXISTS `view_trenery_sportsmena`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`%` SQL SECURITY DEFINER VIEW `view_trenery_sportsmena`  AS SELECT `s`.`FIO` AS `Sportsmen`, `tr`.`FIO` AS `Trener`, `vs`.`Nazvanie` AS `Vid_sporta` FROM (((`sportsmeny` `s` join `trenirovki` `t` on((`s`.`ID` = `t`.`ID_sportsmena`))) join `trenery` `tr` on((`t`.`ID_trenera` = `tr`.`ID`))) join `vidy_sporta` `vs` on((`t`.`ID_vida_sporta` = `vs`.`ID`)))  ;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `Nagrazhdenie`
--
ALTER TABLE `Nagrazhdenie`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `ID_rezultata` (`ID_rezultata`);

--
-- Индексы таблицы `Organizatory_sorevnovaniy`
--
ALTER TABLE `Organizatory_sorevnovaniy`
  ADD PRIMARY KEY (`ID_organizatora_sorevnovaniy`);

--
-- Индексы таблицы `Rezultaty_uchastiya`
--
ALTER TABLE `Rezultaty_uchastiya`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `idx_rezultat_sostyazanie` (`ID_sostyazaniya`),
  ADD KEY `idx_rezultat_sportsmen` (`ID_sportsmena`),
  ADD KEY `idx_rezultat_mesto` (`Mesto`),
  ADD KEY `idx_rezultat_sportsmen_sostyazanie` (`ID_sportsmena`,`ID_sostyazaniya`);

--
-- Индексы таблицы `Sostyazaniya`
--
ALTER TABLE `Sostyazaniya`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `idx_sostyazanie_data` (`Data_provedeniya`),
  ADD KEY `idx_sostyazanie_vid_sporta` (`Vid_sporta_ID`),
  ADD KEY `idx_sostyazanie_sooruzhenie` (`Sportivnoe_sooruzhenie_ID`),
  ADD KEY `idx_sostyazanie_organizator` (`ID_Organizatory_sorevnovaniy`),
  ADD KEY `idx_sostyazanie_data_vid` (`Data_provedeniya`,`Vid_sporta_ID`);

--
-- Индексы таблицы `Sportivnoe_sooruzhenie`
--
ALTER TABLE `Sportivnoe_sooruzhenie`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `idx_sooruzhenie_tip` (`Tip_ID`),
  ADD KEY `idx_sooruzhenie_vmestimost` (`Vmestimost`);

--
-- Индексы таблицы `Sportivnye_kluby`
--
ALTER TABLE `Sportivnye_kluby`
  ADD PRIMARY KEY (`ID_sportivnogo_kluba`);

--
-- Индексы таблицы `Sportsmeny`
--
ALTER TABLE `Sportsmeny`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `idx_sportsmen_razryad` (`Razryad`),
  ADD KEY `idx_sportsmen_klub` (`ID_sportivnogo_kluba`);

--
-- Индексы таблицы `Sportsmeny_log`
--
ALTER TABLE `Sportsmeny_log`
  ADD PRIMARY KEY (`ID_log`);

--
-- Индексы таблицы `Tip_sooruzheniya`
--
ALTER TABLE `Tip_sooruzheniya`
  ADD PRIMARY KEY (`ID`),
  ADD UNIQUE KEY `Nazvanie` (`Nazvanie`);

--
-- Индексы таблицы `Trenery`
--
ALTER TABLE `Trenery`
  ADD PRIMARY KEY (`ID`),
  ADD KEY `idx_trener_vid_sporta` (`Vid_sporta_ID`);

--
-- Индексы таблицы `Trenirovki`
--
ALTER TABLE `Trenirovki`
  ADD PRIMARY KEY (`ID_trenirovki`),
  ADD KEY `idx_trenirovki_trener` (`ID_trenera`),
  ADD KEY `idx_trenirovki_sportsmen` (`ID_sportsmena`),
  ADD KEY `idx_trenirovki_vid_sporta` (`ID_vida_sporta`),
  ADD KEY `idx_trenirovki_sportsmen_data` (`ID_sportsmena`,`Data_nachala`);

--
-- Индексы таблицы `Vidy_sporta`
--
ALTER TABLE `Vidy_sporta`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `Nagrazhdenie`
--
ALTER TABLE `Nagrazhdenie`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `Organizatory_sorevnovaniy`
--
ALTER TABLE `Organizatory_sorevnovaniy`
  MODIFY `ID_organizatora_sorevnovaniy` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `Rezultaty_uchastiya`
--
ALTER TABLE `Rezultaty_uchastiya`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=106;

--
-- AUTO_INCREMENT для таблицы `Sostyazaniya`
--
ALTER TABLE `Sostyazaniya`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=102;

--
-- AUTO_INCREMENT для таблицы `Sportivnoe_sooruzhenie`
--
ALTER TABLE `Sportivnoe_sooruzhenie`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=103;

--
-- AUTO_INCREMENT для таблицы `Sportivnye_kluby`
--
ALTER TABLE `Sportivnye_kluby`
  MODIFY `ID_sportivnogo_kluba` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT для таблицы `Sportsmeny`
--
ALTER TABLE `Sportsmeny`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT для таблицы `Sportsmeny_log`
--
ALTER TABLE `Sportsmeny_log`
  MODIFY `ID_log` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `Tip_sooruzheniya`
--
ALTER TABLE `Tip_sooruzheniya`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `Trenery`
--
ALTER TABLE `Trenery`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT для таблицы `Trenirovki`
--
ALTER TABLE `Trenirovki`
  MODIFY `ID_trenirovki` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=21;

--
-- AUTO_INCREMENT для таблицы `Vidy_sporta`
--
ALTER TABLE `Vidy_sporta`
  MODIFY `ID` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `Nagrazhdenie`
--
ALTER TABLE `Nagrazhdenie`
  ADD CONSTRAINT `nagrazhdenie_ibfk_1` FOREIGN KEY (`ID_rezultata`) REFERENCES `Rezultaty_uchastiya` (`ID`);

--
-- Ограничения внешнего ключа таблицы `Rezultaty_uchastiya`
--
ALTER TABLE `Rezultaty_uchastiya`
  ADD CONSTRAINT `rezultaty_uchastiya_ibfk_1` FOREIGN KEY (`ID_sostyazaniya`) REFERENCES `Sostyazaniya` (`ID`),
  ADD CONSTRAINT `rezultaty_uchastiya_ibfk_2` FOREIGN KEY (`ID_sportsmena`) REFERENCES `Sportsmeny` (`ID`);

--
-- Ограничения внешнего ключа таблицы `Sostyazaniya`
--
ALTER TABLE `Sostyazaniya`
  ADD CONSTRAINT `sostyazaniya_ibfk_1` FOREIGN KEY (`Vid_sporta_ID`) REFERENCES `Vidy_sporta` (`ID`),
  ADD CONSTRAINT `sostyazaniya_ibfk_2` FOREIGN KEY (`Sportivnoe_sooruzhenie_ID`) REFERENCES `Sportivnoe_sooruzhenie` (`ID`),
  ADD CONSTRAINT `sostyazaniya_ibfk_3` FOREIGN KEY (`ID_Organizatory_sorevnovaniy`) REFERENCES `Organizatory_sorevnovaniy` (`ID_organizatora_sorevnovaniy`);

--
-- Ограничения внешнего ключа таблицы `Sportivnoe_sooruzhenie`
--
ALTER TABLE `Sportivnoe_sooruzhenie`
  ADD CONSTRAINT `sportivnoe_sooruzhenie_ibfk_1` FOREIGN KEY (`Tip_ID`) REFERENCES `Tip_sooruzheniya` (`ID`);

--
-- Ограничения внешнего ключа таблицы `Sportsmeny`
--
ALTER TABLE `Sportsmeny`
  ADD CONSTRAINT `sportsmeny_ibfk_1` FOREIGN KEY (`ID_sportivnogo_kluba`) REFERENCES `Sportivnye_kluby` (`ID_sportivnogo_kluba`);

--
-- Ограничения внешнего ключа таблицы `Trenery`
--
ALTER TABLE `Trenery`
  ADD CONSTRAINT `trenery_ibfk_1` FOREIGN KEY (`Vid_sporta_ID`) REFERENCES `Vidy_sporta` (`ID`);

--
-- Ограничения внешнего ключа таблицы `Trenirovki`
--
ALTER TABLE `Trenirovki`
  ADD CONSTRAINT `trenirovki_ibfk_1` FOREIGN KEY (`ID_trenera`) REFERENCES `Trenery` (`ID`),
  ADD CONSTRAINT `trenirovki_ibfk_2` FOREIGN KEY (`ID_sportsmena`) REFERENCES `Sportsmeny` (`ID`),
  ADD CONSTRAINT `trenirovki_ibfk_3` FOREIGN KEY (`ID_vida_sporta`) REFERENCES `Vidy_sporta` (`ID`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
