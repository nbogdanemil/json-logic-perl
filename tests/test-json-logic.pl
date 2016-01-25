#!/usr/bin/perl -w

use strict;
use JSON;
use Data::Dumper;
use lib '../src/NBogdanEmil';
use JsonLogic;

my $logic = '{ "and" : [ {"<" : [ { "var" : "temp" }, 110 ]}, {"==" : [ { "var" : "pie.filling" }, "apple" ] }] }';
my $data = '{ "temp" : 100, "pie" : { "filling" : "apple" } }';
my $JsonLogic = JsonLogic->new();
my $decodedJsonLogic = decode_json($logic);
my $decodedJsonData = decode_json($data);
my $result = $JsonLogic->apply($decodedJsonLogic, $decodedJsonData);

print Dumper $logic;
print Dumper $data;
print Dumper $result;
