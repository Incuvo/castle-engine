from __future__ import absolute_import


_CORE = {
    'gearman': {
        'hosts': ['127.0.0.1'],
        'process_name': 'Castle Queue'
    },
    'services': {
        'amazon': {
            'key': 'AKIAJRL3YEG26A66VDOQ',
            'secret': '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',
        }
    },
    'castle': {}
}


def development():
    return _CORE

def testing():
    return _CORE

def staging():
    return _CORE

def production():
    return _CORE
