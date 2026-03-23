package com.unazed.LibraryManagement;

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