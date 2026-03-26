package com.unazed.LibraryManagement;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

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

  public static <T> SqlApiResult<List<T>> fromResultSetList(
    ResultSet rs, Class<T> clazz)
  {
    try
    {
      boolean success = rs.getBoolean("success");
      String errorCode = rs.getString("error_code");
      if (!success)
          return new SqlApiResult<>(false, errorCode, null);

      String json = rs.getString("data");
      List<T> items = new Gson().fromJson(json,
          TypeToken.getParameterized(List.class, clazz).getType());
      return new SqlApiResult<>(true, null, items);
    }
    catch (SQLException sqlExc)
    {
      throw new RuntimeException(
        "Failed to parse SQL result set (list)", sqlExc);
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