package com.unazed.LibraryManagement.model;

public class User
{
  private String username;
  private String jwtToken;

  public User(String username, String jwtToken)
  {
    this.username = username;
    this.jwtToken = jwtToken;
  }

  public String getUsername()
  {
    return username;
  }

  public String getJwtToken()
  {
    return jwtToken;
  }
}