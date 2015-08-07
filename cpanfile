requires 'Compiler::Lexer', '0.22';
requires 'List::Util';
requires 'List::MoreUtils';
requires 'perl', '5.008001';
requires 'Text::ASCIITable';

on configure => sub {
    requires 'Module::Build::Tiny', '0.035';
};

on test => sub {
    requires 'Test::More', '0.98';
    requires 'Capture::Tiny';
};
