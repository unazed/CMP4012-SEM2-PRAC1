package com.unazed.LibraryManagement.model;

import com.google.gson.Gson;

public class User
{
  private final int id;
  private final String email;
  private final String jwtToken;

  public interface UserAware
  {
    void setUser(User user);
  }

  public User(int id, String email, String jwtToken)
  {
    System.out.println("Creating User: id=" + id + ", email=" + email);
    this.id = id;
    this.email = email;
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

  public String getEmail()
  {
    return email;
  }

  public String getJwtToken()
  {
    return jwtToken;
  }
}