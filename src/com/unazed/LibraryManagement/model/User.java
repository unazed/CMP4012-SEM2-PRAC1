package com.unazed.LibraryManagement.model;

import java.util.List;

import com.google.gson.Gson;

public class User
{
  private final int id;
  private final String email;
  private final String jwtToken;
  private final String username;
  private final String role;
 

  public static enum Role
  {
    Librarian("librarian"), Member("member");

    private final String roleName;

    Role(String roleName)
    {
      this.roleName = roleName;
    }

    public static final List<Role> getAllRoles()
    {
      return List.of(Role.values());
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
    this.role = role;
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
    return Role.fromRoleName(role);
  }

  public String getUsername()
  {
    return username;
  }
}