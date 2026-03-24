package com.unazed.LibraryManagement.model;

import com.google.gson.Gson;

public class User
{
  private final int id;
  private final String email;
  private final String jwtToken;
  private final String username;
  private final Role role;

  public static class UserAware
  {
    private User boundUser;

    public void whenUserAvailable(User user)
    {
      return;
    }

    public void setBoundUser(User user)
    {
      this.boundUser = user;
    }

    public User getBoundUser()
    {
      return boundUser;
    }
  }

  public static enum Role
  {
    Librarian("librarian"), Member("member");

    private final String roleName;
    
    Role(String roleName)
    {
      this.roleName = roleName;
    }

    public String getRoleName()
    {
      return roleName;
    }

    public static Role fromRoleName(String roleName)
    {
      for (Role role : Role.values())
      {
        if (role.getRoleName().equalsIgnoreCase(roleName))
          return role;
      }
      throw new IllegalArgumentException("Invalid role name: " + roleName);
    }
  }

  public User(
    int id, String email, String username, String role, String jwtToken)
  {
    this.id = id;
    this.email = email;
    this.username = username;
    this.role = Role.fromRoleName(role);
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

  public Role getRole()
  {
    return role;
  }

  public String getUsername()
  {
    return username;
  }
}