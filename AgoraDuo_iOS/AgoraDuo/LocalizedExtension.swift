//
//  LocalizedExtension.swift
//  C&T Speaker
//
//  Created by Cindy Qin on 16/4/17.
//  Copyright © 2016年 YueStudio. All rights reserved.
//

import Foundation

extension String {
    /**
     Get a localized string
     
     :returns: the localized string.
     */
    public func localized() -> String {
        return NSLocalizedString(self, comment: self)
    }
}