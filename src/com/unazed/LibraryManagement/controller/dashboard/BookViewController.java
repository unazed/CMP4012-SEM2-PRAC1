package com.unazed.LibraryManagement.controller.dashboard;

import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.gen.UserRole;

@ViewController.ViewName(View.DASHBOARD_VIEW_BOOKS)
@ViewController.AllowedRoles({UserRole.LIBRARIAN, UserRole.MEMBER})
public class BookViewController extends ViewController.UserAwareController
{

}
