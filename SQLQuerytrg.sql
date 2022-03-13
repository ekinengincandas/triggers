
use Triggers

Declare @I as int = 0

while @I <1000
Begin

Declare @itemid as int
Declare @date as datetime	
Declare @amount as int
Declare @iotype as smallint

set @itemid = ROUND(RAND () * 5,0) 	
	if @itemid =0
	  set @itemid = 1

set @date = DATEADD ( day,- ROUND(RAND () * 365,0),GETDATE())  --herhangibir tarih almamýzý saðlar

set @amount = ROUND(RAND () * 9,0) + 1 

set @iotype = ROUND(RAND () * 1,0) + 1  

insert into Itemtransactions (ItemId, Date_, Amount, Iotype) values ( @itemid,@date,@amounth, @iotype )

set @I = @I + 1

End

-----------------  Iotype 1 giriþ iþlemi, 2 çýkýþ

Select Iotype,sum(amount) as 'Miktar' ,COUNT(Iotype) as 'Giriþ - çýkýþ sayýsý' from Itemtransactions where ItemId = 1 group by Iotype


set statistics io on
Select --stok miktarý 
( select sum (amount) from Itemtransactions where Iotype = 1 and ItemId = itm.Id ) -
( select sum (amount) from Itemtransactions where Iotype = 2 and ItemId = itm.Id ) as Stok
from Items itm 

--bu verileri tutacak tablo yapalým.

truncate table stock
truncate table Itemtransactions


insert into stock (ItemId, Stock)
Select Id, 
( select sum (amount) from Itemtransactions where Iotype = 1 and ItemId = itm.Id ) -
( select sum (amount) from Itemtransactions where Iotype = 2 and ItemId = itm.Id ) as Stok
from Items itm order by Id asc

--sýrada itemtransactions tetiklendiðinde stok tablosuda güncellenecek bir trigger yapýsý oluþturacaðýz
--update stock set Stock = 0

------insert trigger

create trigger Trg_transaction_insert
on Itemtransactions
after insert

as
Begin
	Declare @itemid as int
	Declare @amount as int
	Declare @iotype as smallint

	Select @itemid = ItemId, @amount = Amount, @iotype =Iotype from inserted

	if @iotype = 1
		update stock set Stock = Stock + @amount where ItemId = @itemid 
	if @iotype = 2
		update stock set Stock = Stock - @amount where ItemId = @itemid 
End

insert into Itemtransactions (  ItemId, Date_, Amount, Iotype ) values ( 1,GETDATE (),5, 1 )

Select * from Items
Select * from Stock
Select * from Itemtransactions

---------- delete trigger

create trigger Trg_transaction_delete
on Itemtransactions
after Delete
as

Begin

	Declare @itemid as int
	Declare @amount as int
	Declare @iotype as smallint

	select @itemid = ItemId, @amount = Amount, @iotype = Iotype from deleted

	if @iotype = 1
	update Stock set Stock = Stock - @amount where @itemid = ItemId

	if @iotype = 2
	update Stock set Stock = Stock + @amount where @itemid = ItemId

End

insert into Itemtransactions (  ItemId, Date_, Amount, Iotype ) values ( 1,GETDATE (),10, 1 )

Select * from Items
Select * from Stock
Select * from Itemtransactions order by Date_ desc

insert into Itemtransactions (  ItemId, Date_, Amount, Iotype ) values ( 1,GETDATE (),10,2)
delete  from Itemtransactions where ItemId = 1 and Date_ = '2022-03-07 14:02:02.570'

---------- update trigger

--yanlýzca miktar deðiþiyor

Create trigger Trg_transactions_updated
on Itemtransactions 
after Update
as

Begin

	Declare @itemid as int
	Declare @iotype as smallint
	Declare @oldamount as int
	Declare @newamount as int
	Declare @Amount as int

	select @itemid = ItemId, @oldamount = Amount, @iotype = Iotype from deleted
	select @newamount = Amount  from inserted
	select @Amount = @oldamount - @newamount

	if @iotype = 1
	update Stock set Stock = Stock - @amount where  @itemid = ItemId

	if @iotype = 2
	update Stock set Stock = Stock + @amount where  @itemid = ItemId
End
 
Select * from Items
Select * from Stock
Select * from Itemtransactions order by Date_ desc
update Itemtransactions set Amount = '0' where Date_ = '2022-03-07 14:31:55.983' and ItemId = '1'

-------------------  Trigger ile loglama iþlemi

Create trigger Itemtranslog
on Itemtransactions
after Update

as

Begin
Insert into ItemsLog (Id, Itemid, Date_, Amount, Iotype, Actiontype, Logdate, Logusername) select Id, ItemId, Date_, Amount, Iotype,'Update', GETDATE (), suser_name() from Deleted
End

---

Select * from Itemtransactions order by Date_ desc
Select * from Itemslog

UPDATE Itemtransactions SET Amount = '10' where date_ = '2022-03-07 14:31:55.983' and ItemId = 1

--- update atýlýyorsa inserted tablo dolu deleted tablo dolu
--- delete yaplýyorsa inserted tablo boþ deletet tablo dolu

Alter trigger Itemtranslog
on Itemtransactions
after Update,Delete
as

Begin

Declare @DeleteCount as int
Declare @InsertedCount as int

Select @DeleteCount = COUNT (*) from deleted
Select @InsertedCount = COUNT (*) from inserted

DECLARE @Actiontype as varchar (20)

if @DeleteCount > 0 and @InsertedCount > 0
	set @Actiontype = 'Update'

if @DeleteCount > 0 and @InsertedCount = 0
	set @Actiontype = 'Delete'

Insert into ItemsLog (Id, Itemid, Date_, Amount, Iotype, Actiontype, Logdate, Logusername) select Id, ItemId, Date_, Amount, Iotype, @Actiontype, GETDATE (), suser_name() from Deleted
End

Select * from Itemtransactions order by Date_ desc
Select * from Itemslog

UPDATE Itemtransactions SET Amount = '10' where date_ = '2022-03-07 15:42:47.177' and ItemId = 1


