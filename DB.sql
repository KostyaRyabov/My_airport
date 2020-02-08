create database DB
GO
use DB
GO

--=================TABLES=====================--

create table planes(
[id] int Identity(1,1) NOT NULL,
[name] varchar(16) NULL,
[companyID] int NULL,
[size] int default 10 NOT NULL,
[statusID] int NULL,
[dataCreate] datetime NULL default current_timestamp
)
GO

create table company(
[id] int Identity(1,1) NOT NULL,
[name] varchar(16) NULL
)
GO

create table [status](
[id] int Identity(1,1) NOT NULL,
[record] varchar(20) NULL
)
GO

create table hangar(
[id] int Identity(1,1) NOT NULL,
[planesID] int NULL,
[Reserved] BIT NOT NULL,	--(дл€ прилетающих самолетов бронируетс€ [ReadOnly])--
[datetime] datetime default current_timestamp	--(врем€ последнего изменени€ состо€ни€)--
)
GO

create table shedule(
[id] int Identity(1,1) NOT NULL,
[planesID] int NULL,
[hangarID] int NULL,
[wayID] int NULL,
[PassangerCount] int NOT NULL default 0,
[datetime] datetime Not null
)
GO

create table way(
[id] int Identity(1,1) NOT NULL,
country varchar(128) NULL,		--(может быть только либо From, либо To)--
[arrives] BIT NOT NULL,
[nonstop] BIT NOT NULL,
[duration] time NOT NULL
)
GO

--=================Primary_Keys=====================--

ALTER table planes
Add Primary Key (id)
GO

ALTER table company
Add Primary Key (id)
GO

ALTER table [status]
Add Primary Key (id)
GO

ALTER table hangar
Add Primary Key (id)
GO

ALTER table shedule
Add Primary Key (id)
GO

ALTER table way
Add Primary Key (id)
GO

--=================Foreign_keys=====================--

ALTER table planes
ADD CONSTRAINT FK_company_planes
	Foreign Key (companyID) references company(id)
	ON DELETE SET NULL
GO

ALTER table planes
ADD CONSTRAINT FK_status_planes
	Foreign Key (statusID) references [status](id)
	--(т.к. не предусмотрено изменение таблицы состо€ний не будет последствий)--
GO

ALTER table hangar
ADD CONSTRAINT FK_planes_hangar
	Foreign Key (planesID) references planes(id)
	ON DELETE SET NULL
GO

ALTER table shedule
	ADD CONSTRAINT FK_plane_shedule
	Foreign Key (planesID) references planes(id)
	ON DELETE SET NULL
GO

ALTER table shedule
	ADD CONSTRAINT FK_hangar_shedule
	Foreign Key (hangarID) references hangar(id)
	ON DELETE cascade
GO

ALTER table shedule
	ADD CONSTRAINT FK_status_shedule
	Foreign Key (wayID) references way(id)
	ON DELETE SET NULL
GO

--=================INDEXES=====================--

create index hangar_reserved_idx
	on hangar (Reserved)
	include (id)
GO

create index hangar_planesID_idx
	on hangar (planesID)
	include (id)
GO

create index planes_id_companyID_idx
	on planes (id, companyID)
GO

create index company_id_idx
	on company (id)
	include ([name])
GO

create index shedule_wayID_idx
	on shedule (wayID)
	include ([datetime])
GO

create index shedule_planesID_hangarID_idx
	on shedule (planesID, hangarID)
GO

create index way_id_idx
	on way (id)
	include (arrives)
GO

create index status_id_idx
	on [status] (id)
	include (record)
GO
--=================Procedures&Functions=====================--

CREATE PROCEDURE AddPlane(@name varchar(16), @companyID int, @size int)
as	INSERT INTO planes ([name], size, companyID)
	VALUES (@name,@size,@companyID)
GO

CREATE PROCEDURE LowerStatePlane(@isLanding BIT)
as BEGIN TRAN
	UPDATE planes
	set statusID = (select top(1) id from [status] where id < statusID order by id desc)
	FROM planes, shedule
	WHERE	shedule.planesID = planes.id
		AND planes.statusID > 
		CASE
			when (@isLanding = 0) THEN DateDiff(MINUTE, current_timestamp,shedule.[datetime])/((datepart(minute, (select duration from way where shedule.wayID = way.id))+60)/(SELECT count(id) from [status]))
			else (DateDiff(MINUTE, current_timestamp, shedule.[datetime])/((datepart(minute, (select duration from way where shedule.wayID = way.id))+60)/(SELECT count(id) from [status])))
		END;
	if (@@ERROR <> 0) ROLLBACK;
	Save TRAN Save1;

	DELETE shedule
	where id in (select shedule.id from shedule
	INNER JOIN planes on planes.id = shedule.planesID 
	where planes.statusID = (SELECT MIN(id) from [status]));

	if (@@ERROR <> 0) ROLLBACK tran Save1;
COMMIT
GO

CREATE PROCEDURE DeletePlane(@id int)
as	DELETE planes 
	where id = @id
GO

CREATE PROCEDURE Checkshedule
    AS BEGIN TRAN
		exec LowerStatePlane @isLanding = 0;
		exec LowerStatePlane @isLanding = 1;
		if (@@ERROR <> 0) ROLLBACK;
		
		Save TRAN Save1;
		DELETE shedule WHERE DateDiff(MINUTE, current_timestamp, [DateTime]) < 1;
		
		if (@@ERROR <> 0) ROLLBACK tran Save1;
	COMMIT
GO

create function FreeHangarTable()
returns TABLE
as return (	select id
			From hangar
			where Reserved = 0);
GO

create function getOneFreehangar(@randomvalue numeric(18,10))
returns int
as
BEGIN
	declare @val int = (	
		SELECT id
		FROM (
			SELECT COUNT(id) as _MAX
			FROM FreeHangarTable()
			) as a,
			(
			SELECT ROW_NUMBER() OVER (ORDER BY id) AS rowNum, id
			FROM FreeHangarTable()
			GROUP BY id
			) AS b
		GROUP BY rowNum, _MAX, id
		HAVING rowNum = (SELECT FLOOR(@randomvalue*(_MAX-1) + 1))
	)
	return @val;
END
GO

create function getOneWay(@randomvalue numeric(18,10))
returns int
as
BEGIN
	declare @val int = (	
		SELECT id
		FROM (
			SELECT COUNT(id) as _MAX
			FROM way
			) as a,
			(
			SELECT ROW_NUMBER() OVER (ORDER BY id) AS rowNum, id
			FROM way
			GROUP BY id
			) AS b
		GROUP BY rowNum, _MAX, id
		HAVING rowNum = (SELECT FLOOR(@randomvalue*(_MAX-1) + 1))
	)
	return @val;
END
GO

create function FreePlaneTABLE_ALL()
returns TABLE
as return (	select	planes.id,
					planes.[name]
			From planes
			WHERE planes.id != ALL (SELECT planesID from shedule));
GO

create function FreePlaneTABLE_IN()
returns TABLE
as return (	select t.id, t.[name]
			FROM	FreePlaneTABLE_ALL() t
			WHERE   not EXISTS (select id from hangar where planesID = t.id))
GO

create function FreePlaneTABLE_OUT()
returns TABLE
as return (	select t.id, t.[name]
			FROM	FreePlaneTABLE_ALL() t, hangar
			WHERE	hangar.planesID = t.id);
GO

CREATE PROCEDURE Freehangar(@id int)
as UPDATE hangar set Reserved = 0, planesID = NULL WHERE id = @id;
GO

create PROCEDURE getFlightTime(@iL BIT, @NewTime datetime NULL, @RESULT DateTime NULL OUTPUT)
as BEGIN TRAN
	if (@NewTime is NULL) set @NewTime = DateAdd(DAY, 3, current_timestamp);

	Declare @Maxplanes tinyint = (select COUNT(id) From hangar);
	Declare @planesCount tinyint = (select COUNT(id) From hangar Where planesID is not NULL);

	if (@@ERROR <> 0) ROLLBACK;
	SAVE TRAN Save1;

	Declare @isLanding BIT;
	Declare @DT datetime;

	Declare time_cur CURSOR FOR
		SELECT	way.arrives as [isLanding], 
				[DateTime]
		FROM shedule
		INNER JOIN way on shedule.wayID = way.id
		ORDER BY [DateTime] ASC

	if (@@ERROR <> 0) ROLLBACK tran Save1;
	Save TRAN Save2;

	OPEN time_cur;
	Fetch next from time_cur into @iL, @DT;

	if (@isLanding = 0)
	BEGIN
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if (@planesCount > 0) set @planesCount -= 1;
			else if (@iL = 1) set @NewTime = DateADD(HOUR, 1, @DT);

			Fetch next from time_cur into @isLanding, @DT;
		END
	END
	ELSE BEGIN
		WHILE @@FETCH_STATUS = 0
		BEGIN
			if (@planesCount < @Maxplanes)
			set @planesCount += 1
			else if (@iL = 0) set @NewTime = DateADD(HOUR, 1, @DT);

			Fetch next from time_cur into @isLanding, @DT;
		END
	END

	if (@@ERROR <> 0) ROLLBACK tran Save2;

	CLOSE time_cur;
	Deallocate time_cur;

	if (@planesCount >= @Maxplanes) set @RESULT = NULL;

	set @RESULT = @NewTime;
COMMIT
GO

CREATE PROCEDURE AddRecordOnShedule(@wayID int, @DateTime DateTime NULL)
    AS
	BEGIN TRAN
		Declare @freeHangarsCount tinyint = (select COUNT(id) FROM FreeHangarTable());
		Declare @freePlanesCount int = (select COUNT(id) FROM FreePlaneTABLE_ALL());
		DECLARE @planesID int;

		if (@DateTime < CURRENT_TIMESTAMP) set @DateTime = null;

		if (@wayID is null) set @wayID = (select dbo.getOneWay(rand()));

		DECLARE @isLanding BIT = (select arrives from way where id = @wayID);
		
		if (@@ERROR <> 0) ROLLBACK;

		if (@isLanding = 1)
		BEGIN
			if (@freeHangarsCount > 0)
			BEGIN
				set @planesID = (select top(1) newTable.id 
								FROM FreePlaneTABLE_IN() newTable);
				EXEC getFlightTime	@iL = @isLanding, 
									@NewTime = @DateTime, 
									@RESULT = @DateTime OUTPUT;

				if (@@error = 0 AND @planesID is not NULL AND @DateTime is not NULL)
					INSERT INTO shedule (planesID, hangarID, wayID, [DateTime]) 
					VALUES (@planesID,
							(select dbo.getOneFreehangar(rand())), 
							@wayID,
							@DateTime);
				ELSE RAISERROR ('нет доступных самолетов',12,1);
			END
			else RAISERROR ('нет места в авиапарке',12,1);
		END
		ELSE
		BEGIN
			if (@freePlanesCount > 0)
			BEGIN
				set @planesID = (SELECT top(1) newTable.id FROM FreePlaneTABLE_OUT() newTable);
				EXEC getFlightTime @iL = @isLanding, @NewTime = @DateTime, @RESULT = @DateTime OUTPUT;

				if (@@error = 0 AND @planesID is not NULL AND @DateTime is not NULL AND @wayID is not null)
					INSERT INTO shedule (planesID, hangarID, wayID, [DateTime]) 
					VALUES (@planesID,
							(SELECT top(1) hangar.id 
								FROM hangar
								WHERE hangar.planesID = @planesID), 
							@wayID,
							@DateTime);
				ELSE RAISERROR ( 'нет доступных самолетов',12,1);
			END
			else RAISERROR ('в авиапарке нет самолетов',12,1);
		END
	COMMIT
GO

create procedure addNPlanes (@N int, @cID int, @s int)
as BEGIN
	declare @txt varchar(20);
	WHILE @N > 0
	BEGIN
		SET @txt = (SELECT CONCAT('Ѕоинг ',(SELECT CAST(@N as varchar(4)))))
		SET @N = @N - 1
		exec AddPlane @name = @txt, @companyID = @cID, @size = @s
	END;
END
GO

create procedure RUN_indexes(@RUN BIT)
AS BEGIN
	if (@RUN = 0)
	BEGIN
		ALTER INDEX hangar_reserved_idx ON hangar DISABLE;
		ALTER INDEX hangar_planesID_idx ON hangar DISABLE;

		ALTER INDEX shedule_wayID_idx ON shedule DISABLE;
		ALTER INDEX shedule_planesID_hangarID_idx ON shedule DISABLE;

		ALTER INDEX way_id_idx ON way DISABLE;

		ALTER INDEX planes_id_companyID_idx ON planes DISABLE;

		ALTER INDEX status_id_idx ON [status] DISABLE;

		ALTER INDEX company_id_idx ON company DISABLE;
	END
	else BEGIN
		DBCC DBREINDEX("hangar", hangar_reserved_idx);
		DBCC DBREINDEX("hangar", hangar_planesID_idx);

		DBCC DBREINDEX("shedule", shedule_wayID_idx);
		DBCC DBREINDEX("shedule", shedule_planesID_hangarID_idx);

		DBCC DBREINDEX("way", way_id_idx);
		
		DBCC DBREINDEX("planes", planes_id_companyID_idx);
		
		DBCC DBREINDEX("status", status_id_idx);

		DBCC DBREINDEX("company", company_id_idx);
	END
END
GO

--=================Triggers=====================--

create trigger trg_shedule_I on shedule
	after INSERT as
	BEGIN TRAN
		DECLARE @planesID int = (SELECT planesID FROM inserted);
		DECLARE @sheduleID int = (SELECT id from inserted);

		IF (@@error <> 0) ROLLBACK;
		SAVE TRANSACTION Save0;

		update hangar set Reserved = 1
		WHERE id = (SELECT hangarID FROM inserted);

		IF (@@error <> 0) ROLLBACK TRANSACTION Save0;
		SAVE TRANSACTION Save1;
		
		update planes set [statusID] = (select top(1) id from [status] where id < (select Max(id) from [status]) order by id desc) WHERE id = (select planesID FROM inserted);
		IF (@@error <> 0) ROLLBACK TRANSACTION Save1;
	COMMIT
GO

create trigger trg_shedule_D on shedule
	after delete AS
	BEGIN TRAN
		DECLARE @DT datetime = (select [datetime] FROM deleted) - CAST((select duration from way where way.id = (select deleted.id from deleted)) as datetime);
		
		if ((SELECT	arrives
			FROM way
			INNER JOIN shedule on shedule.wayID = way.id
			where shedule.id = (select id from deleted)) = 1)
		BEGIN
				--(в полете)--
			if (DateDIFF(HOUR, current_timestamp, @DT) < 0)
			BEGIN
				DECLARE @iDp int = (SELECT planesID from deleted);
				exec DeletePlane @id = @iDp;
			END
		END
		else
		BEGIN
			DECLARE @iDh int = (SELECT hangarID FROM deleted);
			UPDATE hangar set Reserved = 0 where id = @iDh;
			UPDATE planes set [statusID] = (SELECT MAX(id) from [status]) WHERE id = (SELECT planesID FROM deleted);
		END

		IF (@@error <> 0) ROLLBACK;
	COMMIT
GO

create trigger trg_shedule_U on shedule
	after UPDATE AS
	BEGIN TRAN
		DECLARE @id int = (SELECT id FROM deleted);
		
		if UPDATE(hangarID)
		BEGIN
			DECLARE @hangarID_new int = (select hangarID from inserted);
			DECLARE @hangarID_old int = (select hangarID from deleted);

			if ((select Reserved from hangar where id = @hangarID_new) = 1) 
			BEGIN
				RAISERROR ('ангар зан€т',12,1);
				COMMIT
			END

			SAVE TRANSACTION Save2;
			UPDATE hangar set Reserved = 1 WHERE id = @hangarID_new;
			IF (@@error <> 0) ROLLBACK TRANSACTION Save2;

			SAVE TRANSACTION Save21;
			UPDATE hangar set Reserved = 0 WHERE id = @hangarID_old;
			IF (@@error <> 0) ROLLBACK TRANSACTION Save21;

			SAVE TRANSACTION Save3;
			
			UPDATE shedule set shedule.planesID = (select hangar.planesID from hangar where hangar.id = shedule.hangarID) WHERE id = @hangarID_new;
			IF (@@error <> 0) ROLLBACK TRANSACTION Save3;
		END
		
		if UPDATE(planesID)
		BEGIN
			DECLARE @planesID_new int = (select planesID from inserted);
			DECLARE @planesID_old int = (select planesID from deleted);
			DECLARE @maxStatus int = (SELECT MAX(id) from [status]);
			
			if not ((select planesID FROM shedule where id = @id) = @planesID_new) BEGIN
				if (exists(select * from hangar where planesID = @planesID_new) AND (select Reserved from hangar where planesID = @planesID_new) = 1) RAISERROR ('самолет зан€т',12,1);
				else if ((select statusID from planes where id = @planesID_new) = (select MIN(id) from [status])) RAISERROR ('самолет не исправен',12,1);
				else BEGIN
					SAVE TRANSACTION Save4;
					update planes set [statusID] = @maxStatus where id = @planesID_old;
					IF (@@error <> 0) ROLLBACK TRANSACTION Save4;

					SAVE TRANSACTION Save5;
					update hangar set planesID = @planesID_new where id = (select hangarID from inserted);
					IF (@@error <> 0) ROLLBACK TRANSACTION Save5;

					SAVE TRANSACTION Save6;
					update planes set [statusID] = (select top(1) [status].id from [status] where [status].id < @maxStatus order by [status].id desc) where id = @planesID_new;
					IF (@@error <> 0) ROLLBACK TRANSACTION Save6;
				END
			END
		END
	COMMIT
GO

create trigger trg_planes_D on planes
	instead of Delete AS
	BEGIN TRANSACTION
		DECLARE @pID int = (select id FROM deleted);
		
		update planes set [statusID] = (SELECT MIN(id) from [status]) WHERE id = @pID;

		IF (@@error <> 0) ROLLBACK;
		Save tran save1;

		DECLARE @hID int = (select id from hangar where planesID = @pID);
		exec Freehangar @id = @hID;

		IF (@@error <> 0) ROLLBACK tran save1;
	COMMIT
GO

create trigger trg_planes_I on planes
	after Insert AS
	BEGIN TRANSACTION
		update planes set [statusID] = (SELECT MAX(id) from [status]) WHERE id = (select id FROM inserted);

		IF (@@error <> 0) ROLLBACK;
	COMMIT
GO

create trigger trg_planes_U on planes
	after UPDATE AS
	BEGIN TRANSACTION
		IF not UPDATE(statusID) BEGIN
			SAVE TRAN Save1;
			update planes set [statusID] = (SELECT MAX(id) from [status]) WHERE id = (select id FROM inserted);
			IF (@@error <> 0) ROLLBACK tran Save1;
		END
	COMMIT
GO

create trigger trg_hangar_U on hangar
	after UPDATE AS
	BEGIN TRAN

	declare @id int = (select id from deleted);
	
	if not UPDATE([datetime])
		update hangar set [datetime] = current_timestamp where id = @id;
	
	IF (@@error <> 0) ROLLBACK;

	if UPDATE(planesID)
		BEGIN
			DECLARE @planesID_new int = (select planesID from inserted);
			DECLARE @planesID_old int = (select planesID from deleted);
			
			SAVE TRANSACTION Save1;
			
			if not exists (select * FROM shedule where planesID = @planesID_new)
				update shedule set planesID = @planesID_new where shedule.hangarID = @id;
			
			IF (@@error <> 0) ROLLBACK TRANSACTION Save1;
		END

	COMMIT
GO

create trigger trg_hangar_D on hangar
	after DELETE AS
	BEGIN TRAN
		DECLARE @dpID int = (select planesID from deleted);

		if not exists (select * from shedule where shedule.planesID = @dpID)
			update planes set statusID = (SELECT MAX(id) from [status]) WHERE id = @dpID;
	COMMIT
GO

--=======================INSERT======================--

INSERT INTO [status] ([record]) VALUES ('выведен из стро€')
INSERT INTO [status] ([record]) VALUES ('в эксплуатации')
INSERT INTO [status] ([record]) VALUES ('в ожидании вылета')
INSERT INTO [status] ([record]) VALUES ('загружаетс€')
INSERT INTO [status] ([record]) VALUES ('заправл€етс€')
INSERT INTO [status] ([record]) VALUES ('проходит техосмотр')
INSERT INTO [status] ([record]) VALUES ('в ожидании осмотра')
INSERT INTO [status] ([record]) VALUES ('в наличии')
GO

INSERT INTO company ([name]) VALUES ('старое корыто')
INSERT INTO company ([name]) VALUES ('airMashine')
INSERT INTO company ([name]) VALUES ('R2D2')
INSERT INTO company ([name]) VALUES ('Ћетучка')
INSERT INTO company ([name]) VALUES ('аэроѕо')
GO

exec AddPlane @name = 'Ѕоинг 414', @companyID = 1, @size = 25
exec AddPlane @name = 'Ѕоинг 245', @companyID = 2, @size = 25
exec AddPlane @name = 'не Ѕќ»Ќ√ 32', @companyID = 2, @size = 25
exec AddPlane @name = 'самолетик', @companyID = 1, @size = 50
exec AddPlane @name = 'с321', @companyID = 2, @size = 25
exec AddPlane @name = 'с533', @companyID = 3, @size = 100
exec AddPlane @name = 'Ѕоинг 321', @companyID = 4, @size = 25
GO

exec addNPlanes @N = 75, @cID = 2, @s = 25

INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
INSERT INTO hangar (Reserved) VALUES (0)
GO

UPDATE hangar set planesID = 2 WHERE id = 2
UPDATE hangar set planesID = 4 WHERE id = 4
UPDATE hangar set planesID = 3 WHERE id = 1
GO

insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('A',0,1,'2:00')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('B',0,1,'1:00')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('C',0,1,'1:30')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('D',0,1,'2:30')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('E',0,1,'1:30')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('F',0,1,'2:30')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('G',1,1,'2:10')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('H',1,1,'2:30')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('I',1,1,'2:20')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('J',1,1,'0:30')
insert INTO way (country, [arrives], [nonstop], [duration]) VALUES ('K',1,1,'1:30')
Go

--(дл€ авто определени€ самолета и ангара при наличии)--
exec AddRecordOnShedule @wayID = null, @DateTime=NULL;
GO
--==========================VIEWs=======================--

create view V_planes
AS	SELECT	id,
			[name],
			CASE
				WHEN (planes.id = ANY (SELECT planesID FROM hangar))
				THEN 'на базе'
				ELSE 'отсутствует'
			END AS RO_onBase,
			statusID,
			companyID,
			size,
			200 as maxValue
	FROM planes
GO

create view V_shedule
as	SELECT	shedule.id as id,
			planesID,
			hangarID,
			(SELECT COUNT(Reserved) FROM hangar WHERE Reserved = 0) as RO_FreeHangarCount,
			CASE WHEN (way.arrives = 1) 
				THEN 'прилетает' ELSE 'вылетает'
			END as RO_status,
			wayID,
			shedule.PassangerCount,
			planes.size,		--max
			shedule.[datetime]
	FROM shedule
	INNER JOIN planes ON shedule.planesID = planes.id
	INNER JOIN way on shedule.wayID = way.id
GO

CREATE VIEW V_company
AS	SELECT	company.[id],
			company.[name],
			COUNT(A.id) as [RO_PlaneCount]
	FROM company, (SELECT * FROM planes) as A
	WHERE A.companyID = company.id
	GROUP BY company.[id], company.[name]
GO

CREATE VIEW V_way
as	SELECT	id,
			country,
			arrives,
			nonstop,
			duration
 	FROM way
GO

CREATE VIEW V_status
as	SELECT	id,
			record
	FROM [status]
GO

CREATE VIEW V_hangar
as	SELECT	id,
			planesID,
			(SELECT company.[name] FROM planes
			INNER JOIN company on company.id = planes.companyID
			WHERE planes.id = planesID) as RO_company,
			Reserved,
			[datetime]
	FROM hangar
GO

--=========================Logins=========================--

create role AdminRole
create role GuestRole
GO

GRANT EXECUTE ON OBJECT::AddRecordOnShedule TO AdminRole;
Grant select on FreeHangarTABLE to AdminRole;
Grant select on FreePlaneTABLE_ALL to AdminRole;
GRANT select, insert, update on [status] to AdminRole;
Grant select, insert, update, delete on planes to AdminRole;
Grant select, insert, update, delete on company to AdminRole;
Grant select, insert, update, delete on hangar to AdminRole;
Grant select, insert, update, delete on shedule to AdminRole;
Grant select, insert, update, delete on way to AdminRole;
Grant select, insert, update, delete on V_planes to AdminRole;
Grant select, insert, update, delete on V_company to AdminRole;
Grant select, insert, update, delete on V_hangar to AdminRole;
Grant select, insert, update, delete on V_way to AdminRole;
Grant select, insert, update, delete on V_status to AdminRole;
Grant select, insert, update, delete on V_shedule to AdminRole;
GO

Grant select on FreeHangarTABLE to GuestRole;
Grant select on FreePlaneTABLE_ALL to GuestRole;
Grant select on planes to GuestRole;
Grant select on company to GuestRole;
Grant select on [status] to GuestRole;
Grant select on hangar to GuestRole;
Grant select on shedule to GuestRole;
Grant select on way to GuestRole;
Grant select on V_planes to GuestRole;
Grant select on V_company to GuestRole;
Grant select on V_hangar to GuestRole;
Grant select on V_way to GuestRole;
Grant select on V_status to GuestRole;
Grant select on V_shedule to GuestRole;
GO

CREATE LOGIN AdminL
	WITH PASSWORD='admin',
	DEFAULT_DATABASE = DB;
GO

CREATE LOGIN GuestL
	WITH PASSWORD='user',
	DEFAULT_DATABASE = DB;
GO

create user GuestUser for login GuestL WITH DEFAULT_SCHEMA=[dbo]
create user AdminUser for login AdminL WITH DEFAULT_SCHEMA=[dbo]
GO

alter role GuestRole add member GuestUser;
alter role AdminRole add member AdminUser;
GO

--======================================--

use master
DROP DATABASE DB


--exec addNPlanes @N = 100000, @cID = 4, @s = 100
--exec RUN_indexes @RUN = 1

--set statistics time on 

--select	planes.id,
--		planes.companyID
--From planes
--WHERE planes.id != ALL (SELECT planesID from shedule)
--	AND planes.companyID > 2

--set statistics time off