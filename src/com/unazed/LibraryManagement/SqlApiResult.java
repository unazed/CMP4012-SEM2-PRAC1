package com.unazed.LibraryManagement;

import java.sql.ResultSet;
import java.sql.SQLException;

import com.google.gson.Gson;

public class SqlApiResult<T> implements AutoCloseable
{
  private final boolean success;
  private final String errorCode;
  private final T data;

  public SqlApiResult(boolean success, String errorCode, T data)
  {
    this.success = success;
    this.errorCode = errorCode;
    this.data = data;
  }

  public static <T> SqlApiResult<T> fromResultSet(ResultSet rs, Class<T> clazz)
  {
    try
    {
      boolean success = rs.getBoolean(1);
      String errorCode = rs.getString(2);
      String dataStr = rs.getString(3);
      if (!success)
        return new SqlApiResult<>(false, errorCode, null);
      return new SqlApiResult<>(
        true, null, new Gson().fromJson(dataStr, clazz));
    } catch (SQLException sqlExc)
    {
      throw new RuntimeException("Failed to parse SQL result set", sqlExc);
    }
  }

  @Override
  public void close() { /* No resources to close */ }

  public boolean isSuccess()
  {
    return success;
  }
  
  public String getErrorCode()
  {
    return errorCode;
  }

  public T getData()
  {
    return data;
  }
}