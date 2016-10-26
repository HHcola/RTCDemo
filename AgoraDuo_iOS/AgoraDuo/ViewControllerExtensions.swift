//
//  ViewControllerExtensions.swift
//  C&T Speaker
//
//  Created by Cindy Qin on 16/4/16.
//  Copyright © 2016年 YueStudio. All rights reserved.
//

import UIKit
/**
* Shortcut helpful methods for instantiating UIViewController
*
* @author Cindy Qin
* @version 1.0
*/
extension UIViewController {
    
    /**
    Instantiate given view controller.
    The method assumes that view controller is identified the same as its class
    and view is defined in the same storyboard.
    
    :param: viewControllerClass the class name
    
    :returns: view controller or nil
    */
    func create<T: UIViewController>(_ viewControllerName: String, storyBoardName: String = "Main") -> T? {
        let storyboard = UIStoryboard(name: storyBoardName, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: viewControllerName) as? T
    }
    
    func create<T: UIViewController>(_ viewControllerClass: AnyClass, storyBoardName: String = "Main") -> T? {
        
        let storyboard = UIStoryboard(name: storyBoardName, bundle: nil)
        let className = NSStringFromClass(viewControllerClass).components(separatedBy: ".").last!
        return storyboard.instantiateViewController(withIdentifier: className) as? T
    }
}



/**
 * Extends UIViewController with a few methods that help
 * to load and remove child view controllers.
 *
 * @author Cindy Qin
 * @version 1.0
 */
extension UIViewController {
    
    /**
     Load view from the given view controller into given containerView.
     Uses autoconstraints.
     
     - parameter childVC:       the view controller to load
     - parameter containerView: the view to load in
     */
    func loadChildViewToView(_ childVC: UIViewController, _ containerView: UIView, animation: Bool = false) {
        let childView = childVC.view
        childView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight];
        loadChildViewToViewWithBounds(childVC, containerView, bounds: containerView.bounds, animation: animation)
    }
    
    
    /**
     Load view from the given view controller into given containerView with fixed bounds.
     
     - parameter childVC:       the view controller to load
     - parameter containerView: the view to load in
     - parameter bounds:        the bounds of the loading view
     */
    func loadChildViewToViewWithBounds(_ childVC: UIViewController, _ containerView: UIView, bounds: CGRect, animation: Bool) {
        let childView = childVC.view
        
        childView?.frame = bounds
        
        // Adding new VC and its view to container VC
        self.addChildViewController(childVC)

        childVC.beginAppearanceTransition(true, animated: true)
        containerView.addSubview(childView!)

            childVC.endAppearanceTransition()
            // Finally notify the child view
            childVC.didMove(toParentViewController: self)


    }
    
    /**
     Add the view controller and view into the current view controller
     and given containerView correspondingly without animation.
     Uses autoconstraints.
     
     - parameter childVC:       view controller to load
     - parameter containerView: view to load into
     */
    func loadViewController(_ childVC: UIViewController, _ containerView: UIView) {
        let childView = childVC.view
        childView?.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight];
        loadViewController(childVC, containerView, withBounds: containerView.bounds)
    }
    
    /**
     Add the view controller and view into the current view controller
     and given containerView correspondingly.
     Sets fixed bounds for the loaded view in containerView.
     Constraints can be added manually or automatically.
     
     - parameter childVC:       view controller to load
     - parameter containerView: view to load into
     - parameter bounds:        the view bounds
     */
    func loadViewController(_ childVC: UIViewController, _ containerView: UIView, withBounds bounds: CGRect) {
        let childView = childVC.view
        
        childView?.frame = bounds
        
        // Adding new VC and its view to container VC
        self.addChildViewController(childVC)
        containerView.addSubview(childView!)
        
        // Finally notify the child view
        childVC.didMove(toParentViewController: self)
    }

    
    /**
     Removes view controller form its parent
     
     - parameter vc: the view controller to remove
     */
    func removeViewController(_ animation: Bool = false) {
        self.willMove(toParentViewController: nil)
        

            // Finally remove previous VC
            self.beginAppearanceTransition(false, animated: true)
            self.view.removeFromSuperview()
            self.endAppearanceTransition()

            self.removeFromParentViewController()


    }
    
    /**
     Remove view controller and view from their parents
     */
    func removeFromParent() {
        self.willMove(toParentViewController: nil)
        self.view.removeFromSuperview()
        self.removeFromParentViewController()
    }
    
}




 
