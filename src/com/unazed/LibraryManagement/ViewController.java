package com.unazed.LibraryManagement;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.util.List;

import com.unazed.LibraryManagement.model.gen.UserRole;
import com.unazed.LibraryManagement.model.gen.Users;

public class ViewController
{
  public static class UserAwareController extends ViewController
  {
    private Users boundUser;
    private String boundUserToken;

    public void whenUserAvailable(String userToken)
    {}

    public List<UserRole> getAllowedRoles()
    {
      AllowedRoles annotation
        = this.getClass().getAnnotation(AllowedRoles.class);
      if (annotation == null)
        throw new IllegalStateException(
          "UserAwareController class " + this.getClass().getName() +
          " is missing @AllowedRoles annotation");
      return List.of(annotation.value());
    }

    public final void setBoundUser(Users user)
    {
      this.boundUser = user;
    }

    public final Users getBoundUser()
    {
      return boundUser;
    }

    public final void setBoundUserToken(String userToken)
    {
      this.boundUserToken = userToken;
    }

    public final String getBoundUserToken()
    {
      return boundUserToken;
    }
  }

  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.TYPE)
  public @interface AllowedRoles
  {
    UserRole[] value();
  }

  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.TYPE)
  public @interface ViewName
  {
    View value();
  }

  public View getView()
  {
    return getViewOf(this.getClass()); 
  }

  public boolean postInitialize()
  {
    return true;
  }

  public static View getViewOf(Class<? extends ViewController> controllerClass)
  {
    ViewName annotation = controllerClass.getAnnotation(ViewName.class);
    if (annotation == null)
      throw new IllegalStateException(
        "ViewController class " + controllerClass.getName() +
        " is missing @ViewName annotation");
    return annotation.value();
  }
}
