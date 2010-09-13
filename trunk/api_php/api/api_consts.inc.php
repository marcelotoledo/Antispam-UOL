<?php

//	ERROR CODES
define(	'ccERR_OK',			0		);		//	everything went OK
define(	'ccERR_GENERAL',	-1		);		//	general internal error
define(	'ccERR_STATUS',		-2		);		//	status is not correct
define(	'ccERR_NET_ERROR',	-3		);		//	network data transfer error
define(	'ccERR_TEXT_SIZE',	-4		);		//	text is not of an appropriate size
define(	'ccERR_OVERLOAD',	-5		);		//	server's overloaded
define(	'ccERR_BALANCE',	-6		);		//	not enough funds to complete the request
define(	'ccERR_TIMEOUT',	-7		);		//	request timed out
define(	'ccERR_BAD_PARAMS',	-8		);		//	provided parameters are not good for this function
define(	'ccERR_UNKNOWN',	-200	);		//	unknown error

//	picture processing TIMEOUTS
define( 'ptoDEFAULT',			0		);	//	default timeout, server-specific
define( 'ptoLONG',				1		);	//	long timeout for picture, server-specfic
define( 'pto30SEC',				2		);	//	30 seconds timeout for picture
define( 'pto60SEC',				3		);	//	60 seconds timeout for picture
define( 'pto90SEC',				4		);	//	90 seconds timeout for picture

//	picture processing TYPES
define( 'ptUNSPECIFIED',		0		);	//	picture type unspecified
define( 'ptASIRRA',				86		);	//	picture type - ASIRRA

// multi-picture processing specifics
define(	'ptASIRRA_PICS_NUM',	12		);

?>