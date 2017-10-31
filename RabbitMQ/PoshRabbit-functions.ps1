# Copyright (c) 2010 Code Owls LLC
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy 
#	of this software and associated documentation files (the "Software"), 
#	to deal in the Software without restriction, including without limitation 
#	the rights to use, copy, modify, merge, publish, distribute, sublicense, 
#	and/or sell copies of the Software, and to permit persons to whom the 
# 	Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in 
#	all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
#	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
#	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
#	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
#	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
#	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
#	DEALINGS IN THE SOFTWARE. 
# 
#
# for information regarding this project, to request features or report 
#	issues, please see:
# http://poshrabbit.codeplex.com
#
#
# poshrabbit module functions
#

$script:consumerCache = @{};

function get-cachedConsumer
{
    param( 
        [parameter(
        	mandatory=$true,
            ValueFromPipelineByPropertyName=$true)
		]
		[string] $name
    );
	
    if( $script:consumerCache.ContainsKey( $name ) )                                
    {
        $script:consumerCache[ $name ];                                
    }
<#
.SYNOPSIS
Retrieves the cached RabbitMQ consumer.

.DESCRIPTION
Locates the cached Rabbit MQ consumer (the source of message events
from a RabbitMQ instance) tied to a specific queue name.

.PARAMETER name
Specifies the name of the queue to which the consumer is bound.

.INPUTS
None.

.OUTPUTS
PoshRabbit.IRabbitConsumer. Returns the consumer instance bound to
the specified queue.
#>
}

function cull-splatted
{
    param( 
		[parameter(mandatory=$true,ValueFromPipeline=$true)]
		[hashtable] $a
	);

    $local:nullValueKeys = $a.Keys | where-object {-not $a[$_]};
    $local:nullValueKeys | foreach-object { $a.Remove( $_ ) };
    
    $a;
	<#
	.SYNOPSIS
	Removes any entries with null values from a hashtable.

	.DESCRIPTION
	Removes any entries with null values from a hashtable.  Useful when 
	splatting arguments to a command to remove unnecessary empty or
	unspecified argument values.
	
	.INPUTS
	System.Collections.Hashtable.  The splatted argument hashtable.

	.OUTPUTS
	System.Collections.Hashtable.  The splatted argument hashtable with 
	unspecified arguments removed.
	
	.EXAMPLE
	C:\PS> @{ a=1, b=$null} | cull-splatted
	Name	Value
	----	-----
	a		1
	#>
}

function get-protocol
{
	get-rabbitProtocol;

<#
.SYNOPSIS
Retrieves all available RabbitMQ protocol monikers.

.DESCRIPTION
Retrieves all available RabbitMQ protocol monikers.

A protocol moniker is used with start-consumer and
publish-string to instruct the RabbitMQ client library
what AMQP features to expect the server to support.

.INPUTS
None.

.OUTPUTS
System.String[]. Returns a list of every available
RabbitMQ protocol name.

.LINK
start-consumer
publish-string
#>
}

function get-exchangeType
{
	get-rabbitExchangeType;

<#
.SYNOPSIS
Retrieves all available RabbitMQ exchange types.

.DESCRIPTION
Retrieves all available RabbitMQ exchange types.

An exchange type can be specified in the start-consumer and
publish-message cmdlets.

.INPUTS
None.

.OUTPUTS
System.String[]. Returns a list of every available
RabbitMQ exchange type.

.LINK
start-consumer
publish-string
#>
}

function get-consumer
{
    $script:consumerCache.Values;
	
<#
.SYNOPSIS
Retrieves all active consumers in the current session.

.DESCRIPTION
Returns all active consumers in the current session.

.INPUTS
None.

.OUTPUTS
PoshRabbit.IRabbitConsumer[]. Returns every consumer instance that
exists in the current PowerShell session.

.LINK
receive-consumer
stop-consumer
wait-consumer
#>
}

function start-consumer
{
    param( 
        [parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string] 
		# Specifies the RabbitMQ server to which to connect.
		$hostname,
		
        [parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The name of the exchange to use for messaging.
		$exchange,
        
		[parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The routing key to match.
		$routingkey,
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The name of the queue to use; if unspecified a random queue
		#	name will be used.
		$queuename,
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The name of the new consumer; if unspecified a 
		#	random name will be used.
		$name = [Guid]::NewGuid().ToString('N'),
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The AMQP protocol support moniker to use when connecting
		#	to the RabbitMQ server.
		$protocol = 'AMQP_0_8',
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# Specifies the type of the exchange.  See get-exchangeType
		#	for a complete list.
		$exchangetype = 'topic',
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The name of the RabbitMQ virtual host to which to connect.
		$virtualhost,
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The username to use for authenticating the RabbitMQ connection.
		$username,
		
        [parameter(ValueFromPipelineByPropertyName=$true)]
		[security.securestring] 
		# The password to use for authenticating the RabbitMQ connection.
		$password,
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The encoding to use when translating the message body into a string.
		$encoding,
        		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[scriptBlock] 
		# A script to run for each message received.
        $action
    );
    	
    $local:a = @{
		Name = $name;
        HostName = $hostname;
        Exchange =$exchange;
        ExchangeType =$exchangetype;
        Protocol = $protocol;
        RoutingKey = $routingkey;  
        Queue = $queuename;
        VirtualHost = $virtualHost;
        Username = $username;
        Password =$password;
		Encoding = $encoding;
        } | cull-splatted;
        
    $local:consumer = new-rabbitConsumer @local:a;

    if( $action )
    {
        $local:script = @"
`$local:___dollarunder = `$_;
`$_ = `$eventArgs.MessageData;
try
{
"@ + $action.ToString() + @"
}
catch
{
    new-event -sourceIdentifier 'PoshRabbit.ActionHandler.Error' -eventarguments `$_;
}
finally
{
    `$_ = `$local:dollarunder;
    `$local:___dollarunder = `$null;
}
"@;
        $action = [scriptBlock]::Create( $local:script );
        
        write-debug ( 'action scriptblock: ' + $action.ToString() );
    }
        
    register-objectEvent -inputObject $local:consumer -eventName 'MessageDelivered' -sourceIdentifier $local:consumer.name -supportEvent -action $action;        
        
    $local:consumer | start-rabbitConsumer | out-null;
    
    $script:consumerCache[ $local:consumer.name ] = $local:consumer;
    
    $local:consumer;    
	
<#
.SYNOPSIS
Starts consumption of messages from a RabbitMQ server.

.DESCRIPTION
The start-consumer cmdlet connects to a RabbitMQ server, declares an
exchange and queue, binds the queue to a routing key, and instigates 
retreival of messages from the queue.

Processing the messages can be accomplished in several ways.  To 
automatically run a handler in the background when a message arrives, 
assign a script block to the Action parameter.  To retrieve messages 
on-demand, use the receive-consumer cmdlet.  To block your script until 
a message arrives, use the wait-consumer cmdlet.

Once a consumer is started, it will remain running until your session 
ends, or until explicitly stopped using the stop-consumer cmdlet.

.INPUTS
None.

.OUTPUTS
System.Collections.Hashtable.  The splatted argument hashtable with 
unspecified arguments removed.

.NOTES
The Action ScriptBlock
----------------------

The scriptblock is invoked once for each message received.  
The message is available to the script block as the $_ 
automatic variable.  Any values returned from the script 
are discarded, so you must explicitly pipe the message 
information to an output cmdlet if you wish to persist it.

The $_ variable is of the type 
RabbitMQ.Client.Events.BasicDeliverEventArgs defined in the
RabbitMQ .NET client.  

Any errors that occur during the Action scriptblock are 
caught and published to the event queue of the PowerShell 
session using a source identifier value of 
'PoshRabbit.ActionHandler.Error'.  You can fetch a list 
of the errors that occurred using the get-event cmdlet:

C:\PS>get-event -sourceIdentifier 'PoshRabbit.ActionHandler.Error'

Messages and Encoding
---------------------
When the Encoding parameter is used, an additional note property named 
Message is made available on the BasicDeliverEventArgs.  This property 
contains the binary message body interpreted as a string of the specified 
encoding, if possible.

AMQP Defaults
-------------

By default connections are made using the AMPQ_8_0 
protocol set.

By default exchanges are declared as topic exchanges.  
They are also declared non-passive, non-durable, 
non-autodelete, and non-internal.  

By default queues are declared as non-passing, 
non-durable, exclusive, and autodelete.  In addition, 
queues are created to use auto-acknowledge.

.EXAMPLE
C:\PS> start-consumer -hostname RbtSvr -exchange ps -routingkey 't.?'
Queue                      Name                                    IsRunning
-----                      ----                                    ---------
amq.gen-p+BKZbTX+7rWa/c... df1d85a3bc4548ef91bb177...                   True

Description
-----------
This example starts a consumer using the most basic options.  Messages can
be retrieved using the receive-consumer or wait-consumer cmdlets.

.EXAMPLE
C:\PS> start-consumer -hostname RbtSvr -exchange ps -routingkey 't.?' -action {$_|write-host}


Description
-----------
This example demonstrates responding to messages using a script block.  Each
message received will be piped directly to the write-host cmdlet.

.LINK
RabbitMQ general documentation: http://www.rabbitmq.com/documentation.html
Exchanges: http://www.rabbitmq.com/faq.html#managing-concepts-exchanges
BasicDeliverEventArgs: http://bit.ly/aQq4yw

.LINK
get-protocol
get-exchangeType
receive-consumer
stop-consumer
wait-consumer
publish-string
#>
}

function stop-consumer
{
	[CmdletBinding()]
    param( 
		[parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string]
		# The name of the consumer to stop.
		$name
	);
    
	process
	{
		$local:consumer = get-cachedConsumer $name;
		if( ! $local:consumer )
		{
			return;
		}
		
		$local:event = receive-consumer $name;
		
		unregister-event -sourceIdentifier $local:consumer.name -force;
		$local:consumer | stop-rabbitConsumer | out-null;    
		
		$local:events | foreach-object{ $_.sourceEventArgs.messageData };
	}
<#
.SYNOPSIS
Stops a RabbitMQ consumer.

.DESCRIPTION
The stop-consumer cmdlet stops all message processing and releases
all resources used by the RabbitMQ client.

Once a consumer is passed to the stop-consumer cmdlet, it should be
considered disposed and should be used with any other PoshRabbit cmdlet.

.INPUTS
The consumer instance to stop.

.OUTPUTS
RabbitMQ.Client.Events.BasicDeliverEventArgs[]. Any messages dequeued by
the consumer since the last call to receive-consumer or wait-consumer.

.NOTES
Messages and BasicAck
---------------------
Messages are available during the current PowerShell session and are discarded
one the session ends.  Because the queues created by start-consumer use auto-
acknowledge, messages are considered acknowledged once the consumer dequeues 
them.  Any message dequeued by the consumer will not be requeued in 
the RabbitMQ server.

.EXAMPLE
C:\PS> $q = start-consumer -hostname RbtSvr -exchange ps -routingkey 't.?'
# ...
C:\PS> $q | stop-consumer;


Description
-----------
This example shows how to stop a consumer.

.LINK
start-consumer
#>
}

function wait-consumer
{
    param( 
		[parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string]
		# The name of the consumer on which to wait.
		$name, 
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string]
		# The number of seconds to wait for an event from the consumer.
		#	Specify -1 to wait indefinitely.
		$timeout = (-1) 
	);
    
    $local:consumer = get-cachedConsumer $name;
    if( ! $local:consumer )
    {
        return;
    }
    $local:events = wait-event -sourceIdentifier $local:consumer.name -timeout $timeout;
	if( $local:events )
	{
		$local:events | remove-event;
	}
    $local:events | foreach-object{ $_.sourceEventArgs.messageData };

<#
.SYNOPSIS
Blocks the current PowerShell session until a message is received from
the specified consumer.

.DESCRIPTION
The wait-consumer cmdlet suspends execution until the consumer supplies a
message from the RabbitMQ server.  When the event is received execution 
continues.  To cancel the wait, press CTRL+C.

Use this cmdlet as an alternative to polling for messages with 
receive-consumer.

.INPUTS
The consumer instance on which to wait.  Note that you may only pipe a single 
consumer instance to wait-consumer.

.OUTPUTS
RabbitMQ.Client.Events.BasicDeliverEventArgs. The message received from
the consumer, or $null if the specified timeout elapses before a 
message is available.

.NOTES
Messages and BasicAck
---------------------
Messages are available during the current PowerShell session and 
are discarded one the session ends.  Because the queues created 
by start-consumer use auto-acknowledge, messages are considered 
acknowledged once the consumer dequeues them.  Any message dequeued 
by the consumer that is not retrieved using wait-consumer or 
receive-consumer will not be requeued in the RabbitMQ server.

.EXAMPLE
C:\PS> $q = start-consumer -hostname RbtSvr -exchange ps -routingkey 't.?'
C:\PS> $event = $q | wait-consumer;


Description
-----------
This example shows how to block execution until a message is supplied
by a consumer.  When wait-consumer returns, $event will contain the event
information received from the RabbitMQ server.

.EXAMPLE
C:\PS> $q = start-consumer -hostname RbtSvr -exchange ps -routingkey 't.?'
C:\PS> $event = $q | wait-consumer -timeout 15;


Description
-----------
This example shows how to wait for an event using the optional timeout.  If
no event is available within the 15 second timeout, $event will contain $null.

.LINK
RabbitMQ general documentation: http://www.rabbitmq.com/documentation.html
BasicDeliverEventArgs: http://bit.ly/aQq4yw

.LINK
receive-consumer
start-consumer
stop-consumer
#>
}

function receive-consumer
{
	[CmdletBinding()]
    param( 
		[parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string]
		# The name of the consumer on which to wait.
		$name,
		
		[parameter()]
		[switch]
		# Prevents messages from being removed from the consumer buffer.
		$keep = $false
	);
                    
	process
	{
		$local:consumer = get-cachedConsumer $name;
		if( ! $local:consumer )
		{
			return;
		}
		
		$local:events = get-event | where-object { $_.sourceIdentifier -eq $local:consumer.name };
			
		if( -not $local:events )
		{
			return;
		}
		
		if( -not $keep )
		{
			$local:events | remove-event;
		}
		
		$local:events | foreach-object{ $_.sourceEventArgs.messageData };
	}

<#
.SYNOPSIS
Gets messages received by a RabbitMQ consumer.

.DESCRIPTION
The receive-consumer cmdlet returns any messages dequeued by the consumer
since the previous call to receive-consumer or wait-event.

.INPUTS
The consumer instance from which to receive dequeued messages.

.OUTPUTS
RabbitMQ.Client.Events.BasicDeliverEventArgs[]. All messages received from
the consumer since the previous call to receive-consumer or wait-event, or 
$null if no message has been dequeued.

.NOTES
Messages and BasicAck
---------------------
Messages are available during the current PowerShell session and 
are discarded one the session ends.  Because the queues created 
by start-consumer use auto-acknowledge, messages are considered 
acknowledged once the consumer dequeues them.  Any message dequeued 
by the consumer that is not retrieved using wait-consumer or 
receive-consumer will not be requeued in the RabbitMQ server.

.EXAMPLE
C:\PS> $q = start-consumer -hostname RbtSvr -exchange ps -routingkey 't.?'
C:\PS> $q | receive-consumer


Description
-----------
This example displays all events buffered by the consumer.

.LINK
RabbitMQ general documentation: http://www.rabbitmq.com/documentation.html
BasicDeliverEventArgs: http://bit.ly/aQq4yw

.LINK
start-consumer
stop-consumer
wait-consumer
#>
}

function publish-string
{
	[CmdletBinding()]
    param( 
        [parameter(
			mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
		[string]
		# The message to publish.
		$message,
		
        [parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string] 
		# Specifies the RabbitMQ server to which to connect.
		$hostname,
		
        [parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The name of the exchange to use for messaging.
		$exchange,
        
		[parameter(mandatory=$true,ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The routing key to match.
		$routingkey,
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The AMQP protocol support moniker to use when connecting
		#	to the RabbitMQ server.
		$protocol = 'AMQP_0_8',
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# Specifies the type of the exchange.  See get-exchangeType
		#	for a complete list.
		$exchangetype = 'topic',
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The name of the RabbitMQ virtual host to which to connect.
		$virtualhost,
        
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The username to use for authenticating the RabbitMQ connection.
		$username,
		
        [parameter(ValueFromPipelineByPropertyName=$true)]
		[security.securestring] 
		# The password to use for authenticating the RabbitMQ connection.
		$password,
		
		[parameter(ValueFromPipelineByPropertyName=$true)]
		[string] 
		# The encoding to use when translating the message body into a string.
		$encoding = 'UTF8'
    );
    
	process
	{
		$local:a = @{
			Message = $message;
			HostName = $hostname;
			Exchange =$exchange;
			ExchangeType =$exchangetype;
			Protocol = $protocol;
			RoutingKey = $routingkey;
			Encoding = $encoding;
			VirtualHost = $virtualHost;
			Username = $username;
			Password =$password 
			} | cull-splatted;

		publish-rabbitMessage @local:a;
	}
<#
.SYNOPSIS
Publishes a string to a RabbitMQ exchange.

.DESCRIPTION
The publish-string cmdlet publishes messages to a RabbitMQ 
exchange.

.INPUTS
None.

.OUTPUTS
System.Collections.Hashtable.  The splatted argument hashtable with 
unspecified arguments removed.

.NOTES
The string is packaged into a binary structure using the encoding type 
specified.


AMQP Defaults
-------------

By default connections are made using the AMPQ_8_0 
protocol set.

By default exchanges are declared as topic exchanges.  
They are also declared non-passive, non-durable, 
non-autodelete, and non-internal.  

.EXAMPLE
C:\PS> publish-string -hostname RbtSvr -exchange ps -routingkey 't.x' -message 'this is my message'


Description
-----------
This example publishes a single message.

.EXAMPLE
C:\PS> gc msgs.txt | publish-string -hostname RbtSvr -exchange ps -routingkey 't.x'


Description
-----------
This example publishes each line of text in the file msgs.txt as a 
unique message.

.LINK
RabbitMQ general documentation: http://www.rabbitmq.com/documentation.html
Exchanges: http://www.rabbitmq.com/faq.html#managing-concepts-exchanges

.LINK
get-protocol
get-exchangeType
receive-consumer
start-consumer
stop-consumer
wait-consumer
#>
}

