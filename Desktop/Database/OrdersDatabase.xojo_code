#tag Class
Protected Class OrdersDatabase
Inherits SQLiteDatabase
	#tag Method, Flags = &h0
		Function AddInvoice(invoiceNum As String, invoiceDate As String, invoiceAmount As Currency, customerID As String) As Boolean
		  Dim invoice As New DatabaseRecord
		  invoice.Column("InvoiceNo") = invoiceNum
		  invoice.Column("InvoiceDate") = invoiceDate
		  invoice.CurrencyColumn("InvoiceAmount") = invoiceAmount
		  invoice.Column("CustomerID") = customerID
		  
		  Self.InsertRecord("Invoices", invoice)
		  
		  Return Not Self.Error
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function AddInvoiceItem(code As String, quantity As Integer, invoiceNum As String) As Boolean
		  Dim invoiceRecord As New DatabaseRecord
		  
		  invoiceRecord.Column("InvoiceNo") = invoiceNum
		  invoiceRecord.Column("ProductCode") = code
		  invoiceRecord.IntegerColumn("Quantity") = quantity
		  
		  Self.InsertRecord("InvoiceItems", invoiceRecord)
		  
		  Return Not Self.Error
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub BeginTransaction()
		  Self.SQLExecute("BEGIN TRANSACTION")
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CancelTransaction()
		  Self.Rollback
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function CheckForError() As Boolean
		  If Self.Error Then
		    MsgBox("Database error: " + Self.ErrorMessage)
		  End If
		  
		  Return Self.Error
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function CheckForError(db As Database, msg As String) As Boolean
		  If db.Error Then
		    db.SQLExecute("ROLLBACK TRANSACTION")
		    
		    msg = msg + db.ErrorMessage
		    #If TargetDesktop Then
		      MsgBox(msg)
		    #ElseIf TargetWeb Then
		      App.AppendToDBErrorLog(msg)
		    #Endif
		    
		    Return True
		  End If
		  
		  Return False
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function DeleteInvoiceItems(invoiceNum As String) As Boolean
		  Dim sql As String
		  sql = "DELETE FROM InvoiceItems WHERE InvoiceNo=" + Str(invoiceNum)
		  
		  Self.SQLExecute(sql)
		  
		  Return Not Self.Error
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub EndTransaction()
		  Self.Commit
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FindCustomersByID(ID As String) As RecordSet
		  Dim stmt As PreparedSQLStatement = Self.Prepare("SELECT * FROM Customers WHERE ID=? ORDER BY lastname, firstname")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		  stmt.Bind(0, ID)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Return rs
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function FindCustomersByName(Optional searchName As String) As RecordSet
		  Dim stmt As SQLitePreparedStatement = Self.Prepare("SELECT * FROM Customers WHERE lastname LIKE ? OR firstname LIKE ? ORDER BY lastname, firstname")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		  stmt.BindType(1, SQLitePreparedStatement.SQLITE_TEXT)
		  stmt.Bind(0, SearchName+"%")
		  stmt.Bind(1, SearchName+"%")
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Return rs
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetInvoiceByNumber(invoiceNum As String) As RecordSet
		  Dim stmt As SQLitePreparedStatement = Self.Prepare("SELECT * FROM Invoices WHERE InvoiceNo=?") 
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_INTEGER)
		  stmt.Bind(0, invoiceNum)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Return rs
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetInvoiceItemsForInvoice(invoiceNum As String) As RecordSet
		  Dim stmt As SQLitePreparedStatement = Self.Prepare("SELECT * FROM InvoiceItems INNER JOIN Products ON Products.Code = InvoiceItems.ProductCode WHERE InvoiceNo=?")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_INTEGER)
		  stmt.Bind(0, invoiceNum)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Return rs
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetInvoicesForCustomer(CustomerID As String) As RecordSet
		  //Update the list of invoices to show invoices from the selected customer
		  Dim stmt As PreparedSQLStatement = Self.Prepare("SELECT * FROM Invoices WHERE CustomerID=?")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		  stmt.Bind(0, CustomerID)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Return rs
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetInvoiceYears() As String()
		  // Determine how many unique years there are in the invoices table
		  Dim stmt As PreparedSQLStatement = Self.Prepare("SELECT DISTINCT substr(invoicedate, 1, 4) FROM invoices")
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Dim years() As String
		  
		  If rs <> Nil Then
		    While Not rs.EOF
		      years.Append(rs.IdxField(1).StringValue)
		      rs.MoveNext
		    Wend
		    rs.Close
		  End If
		  
		  Return years
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetMonthlyInvoiceTotalsByYear(year As String) As Integer()
		  // For the specified year, group the invoices by month and then sum the amounts for the month
		  Dim stmt As PreparedSQLStatement = Self.Prepare("SELECT substr(invoicedate, 6, 2), sum(invoiceamount) FROM invoices WHERE substr(invoicedate, 1, 4)  = ? GROUP BY substr(invoicedate, 6, 2)  ORDER BY substr(invoicedate, 6, 2)")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		  stmt.Bind(0, year)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Dim amounts(11) As Integer
		  
		  If rs <> Nil Then
		    While Not rs.EOF
		      // Put the amount for the month into the array
		      amounts(rs.IdxField(1).IntegerValue-1) = rs.IdxField(2).IntegerValue
		      
		      rs.MoveNext
		    Wend
		    rs.Close
		  End If
		  
		  Return amounts
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetNextInvoiceNumber() As Integer
		  Dim rs As RecordSet
		  rs = Self.SQLSelect("SELECT Max(invoiceno) FROM Invoices")
		  
		  If rs <> Nil And Not rs.EOF Then
		    Return rs.IdxField(1).IntegerValue + 1
		  Else
		    Return 1001
		  End If
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetProductByCode(code As String) As RecordSet
		  Dim stmt As SQLitePreparedStatement = Self.Prepare("SELECT * FROM Products WHERE Code = ?")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_TEXT)
		  stmt.Bind(0, code)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  Return rs
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function GetProducts() As RecordSet
		  Dim sql As String = "SELECT * FROM Products"
		  
		  Dim rs As RecordSet
		  rs = Self.SQLSelect(sql)
		  
		  Return rs
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		 Shared Function SetupNewDatabase() As OrdersDatabase
		  // The database file is copied to the App folder using a Build Automation step.
		  
		  Dim msg As String
		  
		  'Make sure we can get to the Orders database on disk
		  Dim sourceDB As FolderItem = GetFolderItem("EddiesElectronics.sqlite")
		  If sourceDB = Nil Or sourceDB.Exists = False Then
		    msg = "Could not find EddiesElectronics.sqlite."
		    #If TargetDesktop Then
		      MsgBox(msg)
		    #ElseIf TargetWeb Then
		      App.AppendToDBErrorLog(msg)
		    #Endif
		    
		    Return Nil
		  End If
		  
		  // Create a blank, in-memory only database so the user can make changes without
		  // affecting the on disk database
		  Dim orders As New OrdersDatabase
		  orders.DatabaseFile = sourceDB
		  If Not orders.Connect Then
		    msg = "Could not connect to " + sourceDB.Name
		    #If TargetDesktop Then
		      MsgBox(msg)
		    #ElseIf TargetWeb Then
		      App.AppendToDBErrorLog(msg)
		    #Endif
		    
		    Return Nil
		  End If
		  
		  Return orders
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function UpdateInvoice(invoiceNum As String, invoiceDate As String, invoiceTotal As Currency) As Boolean
		  Dim stmt As SQLitePreparedStatement = Self.Prepare("SELECT InvoiceNo, CustomerID, InvoiceDate, InvoiceAmount FROM Invoices WHERE InvoiceNo=?")
		  stmt.BindType(0, SQLitePreparedStatement.SQLITE_INTEGER)
		  stmt.Bind(0, invoiceNum)
		  
		  Dim rs As RecordSet = stmt.SQLSelect
		  
		  If rs <> Nil Then
		    rs.Edit
		    rs.Field("InvoiceDate").StringValue = invoiceDate
		    rs.Field("InvoiceAmount").CurrencyValue = invoiceTotal
		    
		    rs.Update
		    
		    rs.Close
		  End If
		  
		  Return Not Self.Error
		End Function
	#tag EndMethod


	#tag ViewBehavior
		#tag ViewProperty
			Name="DatabaseFile"
			Visible=true
			Type="FolderItem"
			EditorType="FolderItem"
		#tag EndViewProperty
		#tag ViewProperty
			Name="DebugMode"
			Visible=true
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="EncryptionKey"
			Visible=true
			Type="String"
			EditorType="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="MultiUser"
			Visible=true
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ShortColumnNames"
			Visible=true
			Type="Boolean"
			EditorType="Boolean"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			Type="String"
		#tag EndViewProperty
		#tag ViewProperty
			Name="ThreadYieldInterval"
			Visible=true
			Type="Integer"
			EditorType="Integer"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Timeout"
			Visible=true
			Type="Double"
			EditorType="Double"
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			Type="Integer"
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
