function run_query
{   [OutputType([System.Data.DataTable])]
    [cmdletbinding()]
    param([string]$sql_stmt)

    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server='.\';Database='tempdb';trusted_connection='True';"
    $conn.Open()
    $query = $sql_stmt
    $command = $conn.CreateCommand()
    $command.CommandTimeout=0
    $command.CommandText = $query
    $result = $command.ExecuteReader()
    $table = new-object "System.Data.DataTable"
    $table.Load($result)
    $conn.Close()
    #$table | Format-Table -AutoSize >> 'g:\setupca\scripts\header.txt'
    return $table
}

function run_update
{
    [cmdletbinding()]
    param([string]$sql_stmt)
    $conn = New-Object System.Data.SqlClient.SqlConnection
    $conn.ConnectionString = "Server='.\';Database='tempdb';trusted_connection='True';"
    $conn.Open()
    $command = $conn.CreateCommand()
    $command.CommandTimeout=900
    $command.CommandText = $sql_stmt
    $rowsAffected = $command.ExecuteNonQuery()
    $conn.Close()
}