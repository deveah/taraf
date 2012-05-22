
/*
 *	taraf.c
 *	the Taraf engine
 *	by Vlad Dumitru - deveah@gmail.com
 *
 *	License: As long as you retain this notice you can do whatever you want
 *	with this source code. Should we meet one day and should you consider
 *	the software worthy, feel free to buy me a beer.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include <fluidsynth.h>

#define TARAF_VERSION 3
#define ERROR_STRING "O eroare de iubire: %s\n"

fluid_settings_t *t_settings;
fluid_synth_t *t_synth;
fluid_audio_driver_t *t_adriver;
fluid_sequencer_t *t_seq;
short t_synth_dest, t_client_dest;
unsigned int global_time = 0;

lua_State *L;
pthread_t lua_thread;

void schedule_callback( int time )
{
	fluid_event_t *ev = new_fluid_event();
	fluid_event_set_source( ev, -1 );
	fluid_event_set_dest( ev, t_client_dest );
	fluid_event_timer( ev, NULL );
	fluid_sequencer_send_at( t_seq, ev, time, 0 );
	delete_fluid_event( ev );
}

void taraf_callback( unsigned int time, fluid_event_t *event,
	fluid_sequencer_t *seq, void *data )
{
	/* generate pattern */
	lua_getglobal( L, "pattern" );
	int r = lua_pcall( L, 0, 0, 0 );
	if( r )
		printf( ERROR_STRING, lua_tostring( L, -1 ) );
}

static int fluid_schedule_callback( lua_State *L )
{
	int time = lua_tointeger( L, -1 );
	schedule_callback( time );

	return 0;
}

static int fluid_init( lua_State *L )
{
	int r = 1;

	t_settings = new_fluid_settings();
	if( t_settings == NULL )
	{
		lua_pushstring( L, "init settings failed" );
		r = 0;
	}

	/* TODO: change driver from within lua */
	fluid_settings_setstr( t_settings, "audio.driver", "alsa" );
	
	t_synth = new_fluid_synth( t_settings );
	if( t_synth == NULL )
	{
		lua_pushstring( L, "init synth failed" );
		r = 0;
	}

	t_adriver = new_fluid_audio_driver( t_settings, t_synth );
	if( t_adriver == NULL )
	{
		lua_pushstring( L, "init audio driver failed" );
		r = 0;
	}

	/* TODO NULL check */
	t_seq = new_fluid_sequencer();

	t_synth_dest = fluid_sequencer_register_fluidsynth( t_seq, t_synth );
	t_client_dest = fluid_sequencer_register_client( t_seq, "taraf",
		taraf_callback, NULL ); 

	/* TODO make returnvalue functional */
	if( r )
		lua_pushstring( L, "ok" );

	lua_pushinteger( L, r );

	return 2;
}

static int fluid_load_sfont( lua_State *L )
{
	char *path = lua_tostring( L, -1 );
	
	int r = fluid_synth_sfload( t_synth, path, 1 );
	if( r == -1 )
		lua_pushstring( L, "err" );
	else
		lua_pushstring( L, "ok" );
	
	return 1;
}

static int fluid_terminate( lua_State *L )
{
	if( t_seq )
		delete_fluid_sequencer( t_seq );
	if( t_adriver )
		delete_fluid_audio_driver( t_adriver );
	if( t_synth )
		delete_fluid_synth( t_synth );
	if( t_settings )
		delete_fluid_settings( t_settings );
	
	return 0;
}

static int fluid_noteon( lua_State *L )
{
	int	time = lua_tointeger( L, -1 ),
		vel  = lua_tointeger( L, -2 ),
		note = lua_tointeger( L, -3 ),
		chn  = lua_tointeger( L, -4 );

	fluid_event_t *ev = new_fluid_event();
	fluid_event_set_source( ev, -1 );
	fluid_event_set_dest( ev, t_synth_dest );
	fluid_event_noteon( ev, chn, note, vel );
	fluid_sequencer_send_at( t_seq, ev, time, 0 );
	delete_fluid_event( ev );

	return 0;
}

static int fluid_noteoff( lua_State *L )
{
	int	time = lua_tointeger( L, -1 ),
		note = lua_tointeger( L, -2 ),
		chn	 = lua_tointeger( L, -3 );

	fluid_event_t *ev = new_fluid_event();
	fluid_event_set_source( ev, -1 );
	fluid_event_set_dest( ev, t_synth_dest );
	fluid_event_noteoff( ev, chn, note );
	fluid_sequencer_send_at( t_seq, ev, time, 0 );
	delete_fluid_event( ev );

	return 0;
}

static int fluid_programchange( lua_State *L )
{
	int prog = lua_tointeger( L, -1 ),
		chn  = lua_tointeger( L, -2 );
	
	fluid_synth_program_change( t_synth, chn, prog );
	
	return 0;
}

static int fluid_sleep( lua_State *L )
{
	int t = lua_tointeger( L, -1 );
	
	usleep( t );

	return 0;
}

static int fluid_get_time( lua_State *L )
{
	lua_pushinteger( L, fluid_sequencer_get_tick( t_seq ) );

	return 1;
}

void *luaT( void *arg )
{
	int r;

	(void) arg;

	r = luaL_dofile( L, "./lua/main.lua" );
	if( r )
	{
		printf( ERROR_STRING, lua_tostring( L, -1 ) );
		return NULL;
	}

	lua_getglobal( L, "init" );
	r = lua_pcall( L, 0, 0, 0 );
	/* TODO errcheck */

	lua_getglobal( L, "pattern" );
	r = lua_pcall( L, 0, 0, 0 );
	if( r )
		printf( ERROR_STRING, lua_tostring( L, -1 ) );
	
	return NULL;
}

void print_usage( char* n )
{
	printf( "usage: %s [style] [base-note] [bpm] [tempo-factor]\n", n );
}

void safe_exit( int e )
{
	if( t_seq )
		delete_fluid_sequencer( t_seq );
	if( t_adriver )
		delete_fluid_audio_driver( t_adriver );
	if( t_synth )
		delete_fluid_synth( t_synth );
	if( t_settings )
		delete_fluid_settings( t_settings );

	exit( e );
}

int main( int argc, char* argv[] )
{
	int r;

	L = lua_open();
	luaL_openlibs( L );

	luaL_Reg fluid[] = {
		{	"init",				fluid_init },
		{	"terminate",		fluid_terminate },
		{	"noteOn",			fluid_noteon },
		{	"noteOff",			fluid_noteoff },
		{	"programChange",	fluid_programchange },
		{	"sleep",			fluid_sleep },
		{	"getTime",			fluid_get_time },
		{	"scheduleCallback",	fluid_schedule_callback },
		{	"loadSFont",		fluid_load_sfont },
		{	NULL,				NULL } };
	luaL_register( L, "fluid", fluid );

	if( argc < 2 )
	{
		print_usage( argv[0] );
		safe_exit( 0 );
	}

	/* arg.style, arg.note, arg.bpm, arg.tempo */
	lua_newtable( L );

	if( argc > 1 )
	{
		lua_pushstring( L, argv[1] );
		lua_setfield( L, -2, "style" );
	}

	if( argc > 2 )
	{
		lua_pushstring( L, argv[2] );
		lua_setfield( L, -2, "note" );
	}

	if( argc > 3 )
	{
		lua_pushinteger( L, atoi( argv[3] ) );
		lua_setfield( L, -2, "bpm" );
	}

	if( argc > 4 )
	{
		lua_pushinteger( L, atoi( argv[4] ) );
		lua_setfield( L, -2, "tempo" );
	}

	lua_setglobal( L, "args" );

	/*r = luaL_loadfile( L, argv[1] );
	if( r )
		printf( "FILE ERROR: %i\n", r );
	r = lua_pcall( L, 0, LUA_MULTRET, 0 );
	if( r )
		printf( ERROR_STRING, lua_tostring( L, -1 ) );
	*/

	r = luaL_dofile( L, "lua/chords.lua" );
	r = luaL_dofile( L, "lua/channels.lua" );
	r = luaL_dofile( L, "lua/drums.lua" );

	r = luaL_dofile( L, argv[1] );
	if( r ) printf( "ERR\n" );

	printf( "taraf %03ialpha -- Dumitru Industries.\n", TARAF_VERSION );

	pthread_create( &lua_thread, NULL, luaT, NULL );

	fflush( stdout );
	getchar();

	pthread_join( lua_thread, NULL );

	lua_getglobal( L, "terminate" );
	lua_pcall( L, 0, 0, 0 );
	/* TODO errcheck */

	return 0;
}
