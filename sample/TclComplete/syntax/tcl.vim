"syntax coloring for procs and commands
"--------------------------------------
syn keyword tclcommand after
syn keyword tclcommand append
syn keyword tclcommand apply
syn keyword tclcommand array
syn keyword tclcommand auto_execok
syn keyword tclcommand auto_import
syn keyword tclcommand auto_load
syn keyword tclcommand auto_load_index
syn keyword tclcommand auto_qualify
syn keyword tclcommand binary
syn keyword tclcommand break
syn keyword tclcommand case
syn keyword tclcommand catch
syn keyword tclcommand cd
syn keyword tclcommand chan
syn keyword tclcommand clock
syn keyword tclcommand close
syn keyword tclcommand concat
syn keyword tclcommand continue
syn keyword tclcommand coroutine
syn keyword tclcommand dict
syn keyword tclcommand encoding
syn keyword tclcommand eof
syn keyword tclcommand error
syn keyword tclcommand eval
syn keyword tclcommand exec
syn keyword tclcommand exit
syn keyword tclcommand expr
syn keyword tclcommand fblocked
syn keyword tclcommand fconfigure
syn keyword tclcommand fcopy
syn keyword tclcommand file
syn keyword tclcommand fileevent
syn keyword tclcommand flush
syn keyword tclcommand for
syn keyword tclcommand foreach
syn keyword tclcommand format
syn keyword tclcommand gets
syn keyword tclcommand glob
syn keyword tclcommand global
syn keyword tclcommand history
syn keyword tclcommand if
syn keyword tclcommand incr
syn keyword tclcommand info
syn keyword tclcommand interp
syn keyword tclcommand join
syn keyword tclcommand lappend
syn keyword tclcommand lassign
syn keyword tclcommand lindex
syn keyword tclcommand linsert
syn keyword tclcommand list
syn keyword tclcommand llength
syn keyword tclcommand lmap
syn keyword tclcommand load
syn keyword tclcommand lrange
syn keyword tclcommand lrepeat
syn keyword tclcommand lreplace
syn keyword tclcommand lreverse
syn keyword tclcommand lsearch
syn keyword tclcommand lset
syn keyword tclcommand lsort
syn keyword tclcommand namespace
syn keyword tclcommand open
syn keyword tclcommand package
syn keyword tclcommand pid
syn keyword tclcommand pl
syn keyword tclcommand proc
syn keyword tclcommand puts
syn keyword tclcommand pwd
syn keyword tclcommand read
syn keyword tclcommand regexp
syn keyword tclcommand regsub
syn keyword tclcommand rename
syn keyword tclcommand return
syn keyword tclcommand scan
syn keyword tclcommand seek
syn keyword tclcommand set
syn keyword tclcommand socket
syn keyword tclcommand source
syn keyword tclcommand split
syn keyword tclcommand string
syn keyword tclcommand subst
syn keyword tclcommand switch
syn keyword tclcommand tailcall
syn keyword tclcommand tclLog
syn keyword tclcommand tell
syn keyword tclcommand throw
syn keyword tclcommand time
syn keyword tclcommand trace
syn keyword tclcommand try
syn keyword tclcommand unknown
syn keyword tclcommand unload
syn keyword tclcommand unset
syn keyword tclcommand update
syn keyword tclcommand uplevel
syn keyword tclcommand upvar
syn keyword tclcommand variable
syn keyword tclcommand vwait
syn keyword tclcommand while
syn keyword tclcommand yield
syn keyword tclcommand yieldto
syn keyword tclcommand zlib
syn keyword tclcommand msgcat::ConvertLocale
syn keyword tclcommand msgcat::DefaultUnknown
syn keyword tclcommand msgcat::GetPreferences
syn keyword tclcommand msgcat::Init
syn keyword tclcommand msgcat::Invoke
syn keyword tclcommand msgcat::ListComplement
syn keyword tclcommand msgcat::Load
syn keyword tclcommand msgcat::LoadAll
syn keyword tclcommand msgcat::mc
syn keyword tclcommand msgcat::mcexists
syn keyword tclcommand msgcat::mcflmset
syn keyword tclcommand msgcat::mcflset
syn keyword tclcommand msgcat::mcforgetpackage
syn keyword tclcommand msgcat::mcload
syn keyword tclcommand msgcat::mcloadedlocales
syn keyword tclcommand msgcat::mclocale
syn keyword tclcommand msgcat::mcmax
syn keyword tclcommand msgcat::mcmset
syn keyword tclcommand msgcat::mcpackageconfig
syn keyword tclcommand msgcat::mcpackagelocale
syn keyword tclcommand msgcat::mcpreferences
syn keyword tclcommand msgcat::mcset
syn keyword tclcommand msgcat::mcunknown
syn keyword tclcommand msgcat::PackageLocales
syn keyword tclcommand msgcat::PackagePreferences
syn keyword tclcommand oo::class
syn keyword tclcommand oo::copy
syn keyword tclcommand oo::define
syn keyword tclcommand oo::InfoClass
syn keyword tclcommand oo::InfoObject
syn keyword tclcommand oo::objdefine
syn keyword tclcommand oo::object
syn keyword tclcommand oo::Slot
syn keyword tclcommand oo::UnknownDefinition
syn keyword tclcommand tcl::Bgerror
syn keyword tclcommand tcl::CopyDirectory
syn keyword tclcommand tcl::HistAdd
syn keyword tclcommand tcl::HistChange
syn keyword tclcommand tcl::HistClear
syn keyword tclcommand tcl::HistEvent
syn keyword tclcommand tcl::HistIndex
syn keyword tclcommand tcl::HistInfo
syn keyword tclcommand tcl::HistKeep
syn keyword tclcommand tcl::HistNextID
syn keyword tclcommand tcl::history
syn keyword tclcommand tcl::HistRedo
syn keyword tclcommand tcl::pkgconfig
syn keyword tclcommand tcl::prefix
syn keyword tclcommand TclComplete::add_args_to_description_dict
syn keyword tclcommand TclComplete::advance_coroutine_to
syn keyword tclcommand TclComplete::cmd_exists
syn keyword tclcommand TclComplete::dict_of_dicts_to_json
syn keyword tclcommand TclComplete::dict_of_lists_to_json
syn keyword tclcommand TclComplete::dict_to_json
syn keyword tclcommand TclComplete::get_all_sorted_commands
syn keyword tclcommand TclComplete::get_hardcoded_cmd_dict
syn keyword tclcommand TclComplete::get_namespace_cmd_dict
syn keyword tclcommand TclComplete::get_subcommands
syn keyword tclcommand TclComplete::info_arrays
syn keyword tclcommand TclComplete::list2keys
syn keyword tclcommand TclComplete::list_to_json
syn keyword tclcommand TclComplete::mkdir_fresh
syn keyword tclcommand TclComplete::next_element_in_list
syn keyword tclcommand TclComplete::remove_final_comma
syn keyword tclcommand TclComplete::write_arrays_json
syn keyword tclcommand TclComplete::write_environment_json
syn keyword tclcommand TclComplete::write_json
syn keyword tclcommand TclComplete::write_json_from_cmd_dict
syn keyword tclcommand TclComplete::write_log
syn keyword tclcommand TclComplete::write_packages_json
syn keyword tclcommand TclComplete::write_regex_char_class_json
syn keyword tclcommand TclComplete::write_vim_tcl_syntax
syn keyword tclcommand TclComplete::WriteFilesStd
syn keyword tclcommand zlib::pkgconfig
syn keyword tclcommand oo::define::constructor
syn keyword tclcommand oo::define::deletemethod
syn keyword tclcommand oo::define::destructor
syn keyword tclcommand oo::define::export
syn keyword tclcommand oo::define::filter
syn keyword tclcommand oo::define::forward
syn keyword tclcommand oo::define::method
syn keyword tclcommand oo::define::mixin
syn keyword tclcommand oo::define::renamemethod
syn keyword tclcommand oo::define::self
syn keyword tclcommand oo::define::superclass
syn keyword tclcommand oo::define::unexport
syn keyword tclcommand oo::define::variable
syn keyword tclcommand oo::Helpers::next
syn keyword tclcommand oo::Helpers::nextto
syn keyword tclcommand oo::Helpers::self
syn keyword tclcommand oo::InfoClass::call
syn keyword tclcommand oo::InfoClass::constructor
syn keyword tclcommand oo::InfoClass::definition
syn keyword tclcommand oo::InfoClass::destructor
syn keyword tclcommand oo::InfoClass::filters
syn keyword tclcommand oo::InfoClass::forward
syn keyword tclcommand oo::InfoClass::instances
syn keyword tclcommand oo::InfoClass::methods
syn keyword tclcommand oo::InfoClass::methodtype
syn keyword tclcommand oo::InfoClass::mixins
syn keyword tclcommand oo::InfoClass::subclasses
syn keyword tclcommand oo::InfoClass::superclasses
syn keyword tclcommand oo::InfoClass::variables
syn keyword tclcommand oo::InfoObject::call
syn keyword tclcommand oo::InfoObject::class
syn keyword tclcommand oo::InfoObject::definition
syn keyword tclcommand oo::InfoObject::filters
syn keyword tclcommand oo::InfoObject::forward
syn keyword tclcommand oo::InfoObject::isa
syn keyword tclcommand oo::InfoObject::methods
syn keyword tclcommand oo::InfoObject::methodtype
syn keyword tclcommand oo::InfoObject::mixins
syn keyword tclcommand oo::InfoObject::namespace
syn keyword tclcommand oo::InfoObject::variables
syn keyword tclcommand oo::InfoObject::vars
syn keyword tclcommand oo::Obj1::my
syn keyword tclcommand oo::Obj10::my
syn keyword tclcommand oo::Obj2::my
syn keyword tclcommand oo::Obj3::my
syn keyword tclcommand oo::Obj4::my
syn keyword tclcommand oo::Obj5::my
syn keyword tclcommand oo::Obj6::my
syn keyword tclcommand oo::Obj7::my
syn keyword tclcommand oo::Obj8::my
syn keyword tclcommand oo::Obj9::my
syn keyword tclcommand oo::objdefine::class
syn keyword tclcommand oo::objdefine::deletemethod
syn keyword tclcommand oo::objdefine::export
syn keyword tclcommand oo::objdefine::filter
syn keyword tclcommand oo::objdefine::forward
syn keyword tclcommand oo::objdefine::method
syn keyword tclcommand oo::objdefine::mixin
syn keyword tclcommand oo::objdefine::renamemethod
syn keyword tclcommand oo::objdefine::unexport
syn keyword tclcommand oo::objdefine::variable
syn keyword tclcommand tcl::array::anymore
syn keyword tclcommand tcl::array::donesearch
syn keyword tclcommand tcl::array::exists
syn keyword tclcommand tcl::array::get
syn keyword tclcommand tcl::array::names
syn keyword tclcommand tcl::array::nextelement
syn keyword tclcommand tcl::array::set
syn keyword tclcommand tcl::array::size
syn keyword tclcommand tcl::array::startsearch
syn keyword tclcommand tcl::array::statistics
syn keyword tclcommand tcl::array::unset
syn keyword tclcommand tcl::binary::decode
syn keyword tclcommand tcl::binary::encode
syn keyword tclcommand tcl::binary::format
syn keyword tclcommand tcl::binary::scan
syn keyword tclcommand tcl::chan::blocked
syn keyword tclcommand tcl::chan::close
syn keyword tclcommand tcl::chan::copy
syn keyword tclcommand tcl::chan::create
syn keyword tclcommand tcl::chan::eof
syn keyword tclcommand tcl::chan::event
syn keyword tclcommand tcl::chan::flush
syn keyword tclcommand tcl::chan::gets
syn keyword tclcommand tcl::chan::names
syn keyword tclcommand tcl::chan::pending
syn keyword tclcommand tcl::chan::pipe
syn keyword tclcommand tcl::chan::pop
syn keyword tclcommand tcl::chan::postevent
syn keyword tclcommand tcl::chan::push
syn keyword tclcommand tcl::chan::puts
syn keyword tclcommand tcl::chan::read
syn keyword tclcommand tcl::chan::seek
syn keyword tclcommand tcl::chan::tell
syn keyword tclcommand tcl::chan::truncate
syn keyword tclcommand tcl::clock::add
syn keyword tclcommand tcl::clock::AddDays
syn keyword tclcommand tcl::clock::AddMonths
syn keyword tclcommand tcl::clock::AssignBaseIso8601Year
syn keyword tclcommand tcl::clock::AssignBaseJulianDay
syn keyword tclcommand tcl::clock::AssignBaseMonth
syn keyword tclcommand tcl::clock::AssignBaseWeek
syn keyword tclcommand tcl::clock::AssignBaseYear
syn keyword tclcommand tcl::clock::BSearch
syn keyword tclcommand tcl::clock::ChangeCurrentLocale
syn keyword tclcommand tcl::clock::ClearCaches
syn keyword tclcommand tcl::clock::clicks
syn keyword tclcommand tcl::clock::ConvertLegacyTimeZone
syn keyword tclcommand tcl::clock::ConvertLocalToUTC
syn keyword tclcommand tcl::clock::DeterminePosixDSTTime
syn keyword tclcommand tcl::clock::EnterLocale
syn keyword tclcommand tcl::clock::format
syn keyword tclcommand tcl::clock::FormatNumericTimeZone
syn keyword tclcommand tcl::clock::FormatStarDate
syn keyword tclcommand tcl::clock::FreeScan
syn keyword tclcommand tcl::clock::GetDateFields
syn keyword tclcommand tcl::clock::getenv
syn keyword tclcommand tcl::clock::GetJulianDayFromEraYearDay
syn keyword tclcommand tcl::clock::GetJulianDayFromEraYearMonthDay
syn keyword tclcommand tcl::clock::GetJulianDayFromEraYearMonthWeekDay
syn keyword tclcommand tcl::clock::GetJulianDayFromEraYearWeekDay
syn keyword tclcommand tcl::clock::GetLocaleEra
syn keyword tclcommand tcl::clock::GetSystemTimeZone
syn keyword tclcommand tcl::clock::GuessWindowsTimeZone
syn keyword tclcommand tcl::clock::InitTZData
syn keyword tclcommand tcl::clock::InterpretHMS
syn keyword tclcommand tcl::clock::InterpretHMSP
syn keyword tclcommand tcl::clock::InterpretTwoDigitYear
syn keyword tclcommand tcl::clock::IsGregorianLeapYear
syn keyword tclcommand tcl::clock::LoadTimeZoneFile
syn keyword tclcommand tcl::clock::LoadWindowsDateTimeFormats
syn keyword tclcommand tcl::clock::LoadZoneinfoFile
syn keyword tclcommand tcl::clock::LocaleNumeralMatcher
syn keyword tclcommand tcl::clock::LocalizeFormat
syn keyword tclcommand tcl::clock::MakeParseCodeFromFields
syn keyword tclcommand tcl::clock::MakeUniquePrefixRegexp
syn keyword tclcommand tcl::clock::mc
syn keyword tclcommand tcl::clock::mcload
syn keyword tclcommand tcl::clock::mclocale
syn keyword tclcommand tcl::clock::mcpackagelocale
syn keyword tclcommand tcl::clock::microseconds
syn keyword tclcommand tcl::clock::milliseconds
syn keyword tclcommand tcl::clock::Oldscan
syn keyword tclcommand tcl::clock::ParseClockFormatFormat
syn keyword tclcommand tcl::clock::ParseClockFormatFormat2
syn keyword tclcommand tcl::clock::ParseClockScanFormat
syn keyword tclcommand tcl::clock::ParseFormatArgs
syn keyword tclcommand tcl::clock::ParsePosixTimeZone
syn keyword tclcommand tcl::clock::ParseStarDate
syn keyword tclcommand tcl::clock::ProcessPosixTimeZone
syn keyword tclcommand tcl::clock::ReadZoneinfoFile
syn keyword tclcommand tcl::clock::scan
syn keyword tclcommand tcl::clock::ScanWide
syn keyword tclcommand tcl::clock::seconds
syn keyword tclcommand tcl::clock::SetupTimeZone
syn keyword tclcommand tcl::clock::UniquePrefixRegexp
syn keyword tclcommand tcl::clock::WeekdayOnOrBefore
syn keyword tclcommand tcl::dict::append
syn keyword tclcommand tcl::dict::create
syn keyword tclcommand tcl::dict::exists
syn keyword tclcommand tcl::dict::filter
syn keyword tclcommand tcl::dict::for
syn keyword tclcommand tcl::dict::get
syn keyword tclcommand tcl::dict::incr
syn keyword tclcommand tcl::dict::info
syn keyword tclcommand tcl::dict::keys
syn keyword tclcommand tcl::dict::lappend
syn keyword tclcommand tcl::dict::map
syn keyword tclcommand tcl::dict::merge
syn keyword tclcommand tcl::dict::remove
syn keyword tclcommand tcl::dict::replace
syn keyword tclcommand tcl::dict::set
syn keyword tclcommand tcl::dict::size
syn keyword tclcommand tcl::dict::unset
syn keyword tclcommand tcl::dict::update
syn keyword tclcommand tcl::dict::values
syn keyword tclcommand tcl::dict::with
syn keyword tclcommand tcl::encoding::convertfrom
syn keyword tclcommand tcl::encoding::convertto
syn keyword tclcommand tcl::encoding::dirs
syn keyword tclcommand tcl::encoding::names
syn keyword tclcommand tcl::encoding::system
syn keyword tclcommand tcl::file::atime
syn keyword tclcommand tcl::file::attributes
syn keyword tclcommand tcl::file::channels
syn keyword tclcommand tcl::file::copy
syn keyword tclcommand tcl::file::delete
syn keyword tclcommand tcl::file::dirname
syn keyword tclcommand tcl::file::executable
syn keyword tclcommand tcl::file::exists
syn keyword tclcommand tcl::file::extension
syn keyword tclcommand tcl::file::isdirectory
syn keyword tclcommand tcl::file::isfile
syn keyword tclcommand tcl::file::join
syn keyword tclcommand tcl::file::link
syn keyword tclcommand tcl::file::lstat
syn keyword tclcommand tcl::file::mkdir
syn keyword tclcommand tcl::file::mtime
syn keyword tclcommand tcl::file::nativename
syn keyword tclcommand tcl::file::normalize
syn keyword tclcommand tcl::file::owned
syn keyword tclcommand tcl::file::pathtype
syn keyword tclcommand tcl::file::readable
syn keyword tclcommand tcl::file::readlink
syn keyword tclcommand tcl::file::rename
syn keyword tclcommand tcl::file::rootname
syn keyword tclcommand tcl::file::separator
syn keyword tclcommand tcl::file::size
syn keyword tclcommand tcl::file::split
syn keyword tclcommand tcl::file::stat
syn keyword tclcommand tcl::file::system
syn keyword tclcommand tcl::file::tail
syn keyword tclcommand tcl::file::tempfile
syn keyword tclcommand tcl::file::type
syn keyword tclcommand tcl::file::volumes
syn keyword tclcommand tcl::file::writable
syn keyword tclcommand tcl::info::args
syn keyword tclcommand tcl::info::body
syn keyword tclcommand tcl::info::cmdcount
syn keyword tclcommand tcl::info::commands
syn keyword tclcommand tcl::info::complete
syn keyword tclcommand tcl::info::coroutine
syn keyword tclcommand tcl::info::default
syn keyword tclcommand tcl::info::errorstack
syn keyword tclcommand tcl::info::exists
syn keyword tclcommand tcl::info::frame
syn keyword tclcommand tcl::info::functions
syn keyword tclcommand tcl::info::globals
syn keyword tclcommand tcl::info::hostname
syn keyword tclcommand tcl::info::level
syn keyword tclcommand tcl::info::library
syn keyword tclcommand tcl::info::loaded
syn keyword tclcommand tcl::info::locals
syn keyword tclcommand tcl::info::nameofexecutable
syn keyword tclcommand tcl::info::patchlevel
syn keyword tclcommand tcl::info::procs
syn keyword tclcommand tcl::info::script
syn keyword tclcommand tcl::info::sharedlibextension
syn keyword tclcommand tcl::info::tclversion
syn keyword tclcommand tcl::info::vars
syn keyword tclcommand tcl::mathfunc::abs
syn keyword tclcommand tcl::mathfunc::acos
syn keyword tclcommand tcl::mathfunc::asin
syn keyword tclcommand tcl::mathfunc::atan
syn keyword tclcommand tcl::mathfunc::atan2
syn keyword tclcommand tcl::mathfunc::bool
syn keyword tclcommand tcl::mathfunc::ceil
syn keyword tclcommand tcl::mathfunc::cos
syn keyword tclcommand tcl::mathfunc::cosh
syn keyword tclcommand tcl::mathfunc::double
syn keyword tclcommand tcl::mathfunc::entier
syn keyword tclcommand tcl::mathfunc::exp
syn keyword tclcommand tcl::mathfunc::floor
syn keyword tclcommand tcl::mathfunc::fmod
syn keyword tclcommand tcl::mathfunc::hypot
syn keyword tclcommand tcl::mathfunc::int
syn keyword tclcommand tcl::mathfunc::isqrt
syn keyword tclcommand tcl::mathfunc::log
syn keyword tclcommand tcl::mathfunc::log10
syn keyword tclcommand tcl::mathfunc::max
syn keyword tclcommand tcl::mathfunc::min
syn keyword tclcommand tcl::mathfunc::pow
syn keyword tclcommand tcl::mathfunc::rand
syn keyword tclcommand tcl::mathfunc::round
syn keyword tclcommand tcl::mathfunc::sin
syn keyword tclcommand tcl::mathfunc::sinh
syn keyword tclcommand tcl::mathfunc::sqrt
syn keyword tclcommand tcl::mathfunc::srand
syn keyword tclcommand tcl::mathfunc::tan
syn keyword tclcommand tcl::mathfunc::tanh
syn keyword tclcommand tcl::mathfunc::wide
syn keyword tclcommand tcl::mathop::!
syn keyword tclcommand tcl::mathop::!=
syn keyword tclcommand tcl::mathop::&
syn keyword tclcommand tcl::mathop::*
syn keyword tclcommand tcl::mathop::**
syn keyword tclcommand tcl::mathop::+
syn keyword tclcommand tcl::mathop::-
syn keyword tclcommand tcl::mathop::/
syn keyword tclcommand tcl::mathop::<
syn keyword tclcommand tcl::mathop::<<
syn keyword tclcommand tcl::mathop::<=
syn keyword tclcommand tcl::mathop::==
syn keyword tclcommand tcl::mathop::>
syn keyword tclcommand tcl::mathop::>=
syn keyword tclcommand tcl::mathop::>>
syn keyword tclcommand tcl::mathop::^
syn keyword tclcommand tcl::mathop::eq
syn keyword tclcommand tcl::mathop::in
syn keyword tclcommand tcl::mathop::ne
syn keyword tclcommand tcl::mathop::ni
syn keyword tclcommand tcl::mathop::|
syn keyword tclcommand tcl::mathop::~
syn keyword tclcommand tcl::namespace::children
syn keyword tclcommand tcl::namespace::code
syn keyword tclcommand tcl::namespace::current
syn keyword tclcommand tcl::namespace::delete
syn keyword tclcommand tcl::namespace::ensemble
syn keyword tclcommand tcl::namespace::eval
syn keyword tclcommand tcl::namespace::exists
syn keyword tclcommand tcl::namespace::export
syn keyword tclcommand tcl::namespace::forget
syn keyword tclcommand tcl::namespace::import
syn keyword tclcommand tcl::namespace::inscope
syn keyword tclcommand tcl::namespace::origin
syn keyword tclcommand tcl::namespace::parent
syn keyword tclcommand tcl::namespace::path
syn keyword tclcommand tcl::namespace::qualifiers
syn keyword tclcommand tcl::namespace::tail
syn keyword tclcommand tcl::namespace::unknown
syn keyword tclcommand tcl::namespace::upvar
syn keyword tclcommand tcl::namespace::which
syn keyword tclcommand tcl::prefix::all
syn keyword tclcommand tcl::prefix::longest
syn keyword tclcommand tcl::prefix::match
syn keyword tclcommand tcl::string::bytelength
syn keyword tclcommand tcl::string::cat
syn keyword tclcommand tcl::string::compare
syn keyword tclcommand tcl::string::equal
syn keyword tclcommand tcl::string::first
syn keyword tclcommand tcl::string::index
syn keyword tclcommand tcl::string::is
syn keyword tclcommand tcl::string::last
syn keyword tclcommand tcl::string::length
syn keyword tclcommand tcl::string::map
syn keyword tclcommand tcl::string::match
syn keyword tclcommand tcl::string::range
syn keyword tclcommand tcl::string::repeat
syn keyword tclcommand tcl::string::replace
syn keyword tclcommand tcl::string::reverse
syn keyword tclcommand tcl::string::tolower
syn keyword tclcommand tcl::string::totitle
syn keyword tclcommand tcl::string::toupper
syn keyword tclcommand tcl::string::trim
syn keyword tclcommand tcl::string::trimleft
syn keyword tclcommand tcl::string::trimright
syn keyword tclcommand tcl::string::wordend
syn keyword tclcommand tcl::string::wordstart
syn keyword tclcommand tcl::tm::add
syn keyword tclcommand tcl::tm::Defaults
syn keyword tclcommand tcl::tm::list
syn keyword tclcommand tcl::tm::path
syn keyword tclcommand tcl::tm::remove
syn keyword tclcommand tcl::tm::roots
syn keyword tclcommand tcl::tm::UnknownHandler
syn keyword tclcommand tcl::unsupported::assemble
syn keyword tclcommand tcl::unsupported::disassemble
syn keyword tclcommand tcl::unsupported::getbytecode
syn keyword tclcommand tcl::unsupported::inject
syn keyword tclcommand tcl::unsupported::representation