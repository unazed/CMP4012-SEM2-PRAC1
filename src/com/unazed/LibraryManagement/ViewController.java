package com.unazed.LibraryManagement;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import com.unazed.LibraryManagement.model.User;

public class ViewController
{
  public static class UserAwareController extends ViewController
  {
    private User boundUser;

    public void whenUserAvailable(User user)
    {}

    public final void setBoundUser(User user)
    {
      this.boundUser = user;
    }

    public final User getBoundUser()
    {
      return boundUser;
    }
  }

  @Retention(RetentionPolicy.RUNTIME)
  @Target(ElementType.TYPE)
  public @interface AllowedRoles
  {
    User.Role[] value();
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
