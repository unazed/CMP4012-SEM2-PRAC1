package com.unazed.LibraryManagement.model;

import com.google.gson.Gson;

public class User
{
  private final int id;
  private final String username;
  private final String jwtToken;

  public interface UserAware
  {
    void setUser(User user);
  }

  public User(int id, String username, String jwtToken)
  {
    this.id = id;
    this.username = username;
    this.jwtToken = jwtToken;
  }

  public static User fromJson(String json)
  {
    return new Gson().fromJson(json, User.class);
  }

  public int getId()
  {
    return id;
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