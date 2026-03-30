package com.unazed.LibraryManagement.controller.dashboard;

import com.unazed.LibraryManagement.View;
import com.unazed.LibraryManagement.ViewController;
import com.unazed.LibraryManagement.model.gen.UserRole;

@ViewController.ViewName(View.DASHBOARD_VIEW_ALL_LOANS)
@ViewController.AllowedRoles({UserRole.LIBRARIAN})
public class LoanViewController extends ViewController.UserAwareController
{

}
