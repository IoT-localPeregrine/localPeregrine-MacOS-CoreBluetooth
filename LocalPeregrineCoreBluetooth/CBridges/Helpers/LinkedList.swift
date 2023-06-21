//
//  LinkedList.swift
//  LocalPeregrineCPP
//
//  Created by Булат Мусин on 21.06.2023.
//

import Foundation

struct List<T> {
    var head: UnsafeMutablePointer<ListNode<T>>?
    var tail: UnsafeMutablePointer<ListNode<T>>?
    var asArray: [ListNode<T>]
    var count: Int
}

struct ListNode<T> {
    var data: T
    var next: UnsafeMutablePointer<ListNode<T>>?
}
