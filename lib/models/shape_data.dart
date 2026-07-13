import 'package:flutter/material.dart';

enum ShapeType { circle, square, triangle, star, rectangle, hexagon, oval }

class ShapeData {
  final String id;
  final String name;
  final ShapeType type;
  final Color color;
  const ShapeData({required this.id, required this.name, required this.type, required this.color});
}

const List<ShapeData> shapes = [
  ShapeData(id: 'circle',    name: 'Circle',    type: ShapeType.circle,    color: Color(0xFFFF6B6B)),
  ShapeData(id: 'square',    name: 'Square',    type: ShapeType.square,    color: Color(0xFF4D96FF)),
  ShapeData(id: 'triangle',  name: 'Triangle',  type: ShapeType.triangle,  color: Color(0xFFFFD93D)),
  ShapeData(id: 'star',      name: 'Star',      type: ShapeType.star,      color: Color(0xFFc471f5)),
  ShapeData(id: 'rectangle', name: 'Rectangle', type: ShapeType.rectangle, color: Color(0xFF51CF66)),
  ShapeData(id: 'hexagon',   name: 'Hexagon',   type: ShapeType.hexagon,   color: Color(0xFFFF9F43)),
  ShapeData(id: 'oval',      name: 'Oval',      type: ShapeType.oval,      color: Color(0xFF00CEC9)),
];
